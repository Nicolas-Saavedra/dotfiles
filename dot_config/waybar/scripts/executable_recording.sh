#!/usr/bin/env bash
# Waybar module: visible only while a screen recording is running.
#
# Ports Omarchy 4's `ScreenRecording` bar indicator (MIT). Super+Shift+R starts
# gpu-screen-recorder with no on-screen feedback at all, so a forgotten
# recording just keeps filling the disk; this is the missing tell.
#
# Elapsed time comes from the process start (ps -o etimes=), so record-toggle.sh
# needs no changes and no state file has to be kept in sync.
set -uo pipefail

# Must match the pattern record-toggle.sh uses, or the two disagree about
# whether a recording exists.
PATTERN='gpu-screen-recorder -w'
OUTDIR="$HOME/Videos/Recordings"

# record-toggle.sh matches on the full cmdline because the kernel truncates comm
# to 15 chars. Same match here so the two never disagree, but the candidates are
# then confirmed against comm, so an unrelated shell that merely happens to carry
# the string in its argv (a grep, an editor, this script under test) is ignored.
pid=""
for candidate in $(pgrep -f "$PATTERN" 2>/dev/null); do
  read -r comm < "/proc/$candidate/comm" 2>/dev/null || continue
  case "$comm" in gpu-screen-reco*) pid="$candidate"; break ;; esac
done

case "${1:---json}" in
  --stop)
    [ -n "$pid" ] && pkill -SIGINT -f "$PATTERN"
    ;;

  --json)
    if [ -z "$pid" ]; then
      # Empty text collapses the module, so the bar shows nothing when idle.
      printf '%s\n' '{"text":"","tooltip":""}'
      exit 0
    fi

    secs="$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ')"
    [ -z "$secs" ] && secs=0
    printf -v clock '%d:%02d' "$((secs / 60))" "$((secs % 60))"

    latest="$(ls -1t "$OUTDIR" 2>/dev/null | head -1)"
    [ -z "$latest" ] && latest="(none yet)"

    # nf-md-record, emitted as an escape for the same reason as weather.sh.
    icon="$(printf '\U000F044B')"
    jq -nc --arg clock "$clock" --arg file "$latest" --arg dir "$OUTDIR" --arg icon "$icon" '
      def esc: tostring | gsub("&";"&amp;") | gsub("<";"&lt;") | gsub(">";"&gt;");
      { text: ($icon + "  REC " + $clock),
        class: "recording",
        alt: "recording",
        tooltip: ("<b>Recording</b>  " + ($clock|esc)
          + "\nWriting to  " + ($dir|esc)
          + "\nLatest      " + ($file|esc)
          + "\n\nClick to stop, or Super + Shift + R") }'
    ;;
esac
