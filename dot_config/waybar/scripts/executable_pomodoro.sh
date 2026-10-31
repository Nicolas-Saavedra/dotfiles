#!/usr/bin/env bash
# Waybar module: a pomodoro timer with no daemon behind it.
#
# The bar already polls this script once a second, so that poll *is* the clock:
# --json reads the state file, notices when the current phase has run out,
# advances it and fires the notification. Nothing runs while the bar is down,
# which is the right failure mode for something that only exists to be looked at.
#
# The cycle is work -> break -> work ..., with a long break every LONG_EVERY
# work sessions. Breaks start on their own the moment work ends (the break
# clock should not wait on you noticing); work does not -- when a break runs
# out the timer parks, armed, until you click. Come back from a twenty-minute
# coffee and the bar says "ready", not "you are eleven minutes into a session".
#
#   Left click    start / pause / resume
#   Right click   stop and reset to idle
#   Middle click  skip the rest of this phase
#
# Durations can be overridden in ~/.config/waybar/pomodoro.conf, same shape as
# weather.conf:   WORK_MIN=50   SHORT_MIN=10   LONG_MIN=20   LONG_EVERY=3
set -uo pipefail

CONF="$HOME/.config/waybar/pomodoro.conf"
# Runtime dir, not ~/.cache: a pomodoro should not outlive the session that
# started it. Logging out ends the timer, which is what you meant anyway.
STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-pomodoro.state"
LOCK="$STATE.lock"

WORK_MIN=25
SHORT_MIN=5
LONG_MIN=15
LONG_EVERY=4
[ -r "$CONF" ] && . "$CONF"

# Nerd-font glyphs as escapes rather than literals, for the same reason
# weather.sh and recording.sh do it: they survive an editor that is not sure
# which encoding it is in.
I_IDLE="$(printf '\U000F13AB')"   # nf-md-timer_outline
I_WORK="$(printf '\U000F13AD')"   # nf-md-timer
I_BREAK="$(printf '\U000F0176')"  # nf-md-coffee
I_PAUSE="$(printf '\U000F03E4')"  # nf-md-pause
I_PLAY="$(printf '\U000F040A')"   # nf-md-play

dur() {
  case "$1" in
    work)  echo $((WORK_MIN  * 60)) ;;
    short) echo $((SHORT_MIN * 60)) ;;
    long)  echo $((LONG_MIN  * 60)) ;;
  esac
}

label() {
  case "$1" in
    work)  echo "Work" ;;
    short) echo "Short break" ;;
    long)  echo "Long break" ;;
  esac
}

# --- state --------------------------------------------------------------------
# One space-separated line: phase running end left round day done
#   running=1  ->  `end` is the epoch second the phase is over
#   running=0  ->  `left` is the seconds still owed, frozen
#   round      ->  work sessions finished in this set, for the long-break count
#   day/done   ->  completed work sessions today, reset when the date rolls over
phase=idle; running=0; end=0; left=0; round=0; day=""; done_today=0

read_state() {
  # `read` fails on an empty or partial file but still blanks every variable it
  # was given, so the sanitising below runs unconditionally -- an empty state
  # file has to come back as idle, not as a phase named "".
  [ -r "$STATE" ] && read -r phase running end left round day done_today < "$STATE" 2>/dev/null
  # A truncated or hand-edited file must not turn into a shell arithmetic error
  # on every poll, so anything non-numeric falls back to a resting state.
  case "${phase:-}" in work|short|long) ;; *) phase=idle ;; esac
  for v in running end left round done_today; do
    [[ ${!v-} =~ ^[0-9]+$ ]] || printf -v "$v" '%s' 0
  done
}

write_state() {
  printf '%s %s %s %s %s %s %s\n' \
    "$phase" "$running" "$end" "$left" "$round" "${day:--}" "$done_today" > "$STATE"
}

alert() {
  # Detached: the bar's poll must not wait on a notification daemon or on
  # pulse. -a groups them under one app in swaync's history.
  local urgency="$1" title="$2" body="$3" sound="$4"
  notify-send -a Pomodoro -u "$urgency" "$title" "$body" >/dev/null 2>&1 &
  [ -r "$sound" ] && command -v paplay >/dev/null 2>&1 && paplay "$sound" >/dev/null 2>&1 &
}

SND_DIR=/usr/share/sounds/freedesktop/stereo

begin() {  # begin <phase>: start it running now
  phase="$1"; running=1; left=0
  end=$(( $(date +%s) + $(dur "$phase") ))
}

arm() {    # arm <phase>: load it, but wait for a click
  phase="$1"; running=0; end=0
  left=$(dur "$phase")
}

# Move past a phase that has run out. `base` is the second it ended, so a
# chain of phases stays on the schedule the first one set rather than drifting
# by however long the bar took to notice.
advance() {
  local base="$1" quiet="${2:-}"
  if [ "$phase" = work ]; then
    round=$((round + 1))
    done_today=$((done_today + 1))
    local next=short
    [ $((round % LONG_EVERY)) -eq 0 ] && next=long
    phase="$next"; running=1; left=0; end=$((base + $(dur "$next")))
    [ -n "$quiet" ] || alert normal "$(label "$next")" \
      "$(( $(dur "$next") / 60 )) minutes. Step away from it." "$SND_DIR/complete.oga"
  else
    arm work
    [ -n "$quiet" ] || alert critical "Break over" \
      "Click the bar when you are ready for $WORK_MIN more minutes." "$SND_DIR/alarm-clock-elapsed.oga"
  fi
}

# Roll the clock forward to now. Called under the lock by every subcommand, so
# a click and a poll can never both decide the phase is over.
tick() {
  local now today
  now=$(date +%s)
  today=$(date +%F)

  if [ "$day" != "$today" ]; then day="$today"; done_today=0; fi

  [ "$phase" = idle ] && return 0

  [ "$running" = 1 ] || return 0
  [ "$now" -lt "$end" ] && return 0

  advance "$end"

  # Still expired after one step means nobody was watching -- a suspend, or the
  # bar restarting hours later. Park rather than replaying a whole afternoon of
  # phases and notifications at once.
  if [ "$running" = 1 ] && [ "$now" -ge "$end" ]; then arm work; fi
}

# --- commands -----------------------------------------------------------------
cmd_toggle() {
  case "$phase:$running" in
    idle:*) round=0; begin work; day=$(date +%F) ;;
    *:1)    left=$(( end - $(date +%s) )); [ "$left" -lt 1 ] && left=1; running=0; end=0 ;;
    *:0)    running=1; end=$(( $(date +%s) + left )); left=0 ;;
  esac
}

cmd_skip() {
  [ "$phase" = idle ] && return 0
  advance "$(date +%s)" quiet
}

# Keeps the state file so the day's tally survives a stop; only the timer resets.
cmd_stop() { phase=idle; running=0; end=0; left=0; round=0; write_state; }

emit() {
  local text cls tip secs

  if [ "$phase" = idle ]; then
    jq -nc --arg icon "$I_IDLE" --arg w "$WORK_MIN" \
      '{ text: $icon, class: ["idle"], alt: "idle",
         tooltip: ("<b>Pomodoro</b>  idle\n" + $w + " minute sessions\n\nClick to start") }'
    return
  fi

  if [ "$running" = 1 ]; then
    secs=$(( end - $(date +%s) ))
    [ "$secs" -lt 0 ] && secs=0
    if [ "$phase" = work ]; then text="$I_WORK"; cls=work; else text="$I_BREAK"; cls=break; fi
  else
    secs="$left"
    # An armed phase shows play, a mid-phase pause shows pause: the icon says
    # whether you stopped this or it is waiting on you.
    if [ "$secs" -eq "$(dur "$phase")" ]; then text="$I_PLAY"; else text="$I_PAUSE"; fi
    cls=paused
  fi

  printf -v text '%s  %d:%02d' "$text" "$((secs / 60))" "$((secs % 60))"

  # Last minute of a running phase gets a second class so the CSS can make it
  # impossible to miss without needing to know which phase it is.
  local classes; classes="$cls"
  if [ "$running" = 1 ] && [ "$secs" -le 60 ]; then classes="$cls ending"; fi

  # Which session of the set this is. During work it is the one under way;
  # during a break it is the one just finished, so `round` is already past it.
  local n
  if [ "$phase" = work ]; then n=$(( (round % LONG_EVERY) + 1 ))
  else n=$(( ((round - 1) % LONG_EVERY) + 1 )); fi

  jq -nc \
    --arg text "$text" --arg cls "$cls" --arg classes "$classes" \
    --arg name "$(label "$phase")" \
    --arg clock "$(printf '%d:%02d' "$((secs / 60))" "$((secs % 60))")" \
    --arg state "$([ "$running" = 1 ] && echo running || echo paused)" \
    --arg round "$n" \
    --arg every "$LONG_EVERY" --arg done "$done_today" \
    --arg at "$([ "$running" = 1 ] && date -d "@$end" +%H:%M || echo '')" '
    def esc: tostring | gsub("&";"&amp;") | gsub("<";"&lt;") | gsub(">";"&gt;");
    { text: $text,
      class: ($classes | split(" ")),
      alt: $cls,
      tooltip: ("<b>" + ($name|esc) + "</b>  " + ($clock|esc) + " left"
        + (if $state == "paused" then "  (paused)" else "" end)
        + "\nSession " + ($round|esc) + " of " + ($every|esc)
        + "  ·  " + ($done|esc) + " done today"
        + (if $at != "" then "\nEnds at " + ($at|esc) else "" end)
        + "\n\nClick to " + (if $state == "running" then "pause" else "resume" end)
        + " · Right-click to stop · Middle-click to skip") }'
}

# Every path that can change the state takes the lock, so the once-a-second
# poll and a click arriving mid-write cannot interleave.
exec 9>"$LOCK"
flock -w 2 9 || { printf '%s\n' '{"text":"","tooltip":""}'; exit 0; }

read_state
tick

case "${1:---json}" in
  --toggle) cmd_toggle; write_state ;;
  --stop)   cmd_stop ;;
  --skip)   cmd_skip; write_state ;;
  --json)   write_state; emit ;;
  *)        printf 'usage: %s [--json|--toggle|--stop|--skip]\n' "${0##*/}" >&2; exit 2 ;;
esac
