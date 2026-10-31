#!/usr/bin/env bash
# Waybar module: Tailscale state, tailnet, exit node and peer count.
#
# Ports the readable half of Omarchy 4's `omarchy.tailscale` Quickshell panel
# (MIT) down to what a waybar custom module can carry: one glyph and a tooltip.
#
#   left click   switch to the next profile
#   right click  bring the current profile up / down
#
# Profiles are read live from `tailscale switch --list --json`, so nothing here
# hardcodes a tailnet: adding or renaming an account is picked up on the next
# poll. The bar label is the profile nickname (`tailscale switch --nickname`),
# title-cased, unless overridden in LABEL_OVERRIDES below.
#
# `tailscale status --json` needs no privileges, but the profile list and both
# click paths do. tailscaled grants write access to a non-root caller by exactly
# two routes (ipnauth.ConnIdentity.IsReadonlyConn, v1.102.3): the caller's uid
# matches the OperatorUser pref, or the caller is root. There is no group and no
# polkit -- isLocalAdmin() is hardcoded to fail on Linux. Either of these works,
# and run_privileged tries both in turn:
#
#   A. sudo tailscale set --operator=$USER
#      OperatorUser lives in ipn.Prefs, which is PER-PROFILE, so run it once on
#      each profile or switching strands you on the far side.
#   B. a NOPASSWD sudoers rule for /usr/bin/tailscale -- narrower, and
#      profile-independent because root always has access.
set -uo pipefail

# Optional "<nickname>|<label>" pretty-names. Anything not listed just gets its
# nickname title-cased, which is usually enough.
LABEL_OVERRIDES=()

notify() { notify-send -a Tailscale "$1" "${2:-}" 2>/dev/null || true; }
status_json() { timeout 4 tailscale status --json 2>/dev/null; }

# Run a tailscale subcommand needing write access. Direct first (works when
# OperatorUser covers the current profile), then non-interactive sudo (works when
# a sudoers rule allows it). -n never prompts, so a missing rule fails fast
# instead of hanging the bar on a password prompt.
# Prints output; returns 0 ok, 1 denied, 2 other failure.
run_privileged() {
  local out
  if out="$(timeout 20 tailscale "$@" 2>&1)"; then printf '%s' "$out"; return 0; fi
  if printf '%s' "$out" | grep -qiE 'denied|permission|root|operator'; then
    if out="$(timeout 20 sudo -n tailscale "$@" 2>&1)"; then printf '%s' "$out"; return 0; fi
    printf '%s' "$out"; return 1
  fi
  printf '%s' "$out"; return 2
}

profiles_json() { run_privileged switch --list --json 2>/dev/null; }

label_for() {  # $1 = nickname (may be empty) ; $2 = fallback tailnet name
  local nick="$1" entry
  for entry in ${LABEL_OVERRIDES[@]+"${LABEL_OVERRIDES[@]}"}; do
    [ "${entry%%|*}" = "$nick" ] && { printf '%s' "${entry#*|}"; return; }
  done
  if [ -n "$nick" ]; then
    printf '%s' "${nick^}"          # blinka -> Blinka
  else
    printf '%s' "${2%%.*}"          # no nickname set: first label of the tailnet
  fi
}

denied_hint() {
  notify "Tailscale is read-only" \
    "Grant one of:
  sudo tailscale set --operator=\$USER   (per profile)
  a NOPASSWD sudoers rule for tailscale"
}

# Default to the read-only path: a bare invocation must never mutate state.
case "${1:---json}" in
  --switch)
    list="$(profiles_json)" || { denied_hint; exit 0; }
    count="$(printf '%s' "$list" | jq 'length' 2>/dev/null || echo 0)"
    if [ "${count:-0}" -lt 2 ]; then
      notify "Only one Tailscale profile" \
        "Add another with:  tailscale login --nickname=<name>"
      exit 0
    fi
    # Cycle in the order the daemon reports, wrapping past the selected entry.
    target="$(printf '%s' "$list" | jq -r '
      (map(.selected) | index(true)) as $i
      | .[ (($i // -1) + 1) % length ] | .id')"
    nick="$(printf '%s' "$list" | jq -r --arg id "$target" '.[] | select(.id == $id) | .nickname // ""')"
    out="$(run_privileged switch "$target")"; rc=$?
    case $rc in
      0) notify "Switched to $(label_for "$nick" "")" ;;
      1) denied_hint ;;
      *) notify "Switch failed" "$out" ;;
    esac
    ;;

  --toggle)
    state="$(status_json | jq -r '.BackendState // "NoState"')"
    if [ "$state" = "Running" ]; then verb=down; else verb=up; fi
    out="$(run_privileged "$verb")"; rc=$?
    case $rc in
      0) notify "Tailscale $verb" ;;
      1) denied_hint ;;
      *) notify "tailscale $verb failed" "$out" ;;
    esac
    ;;

  --json)
    raw="$(status_json)"
    if [ -z "$raw" ]; then
      printf '%s\n' '{"text":"unreachable","class":"error","tooltip":"Tailscale: daemon unreachable"}'
      exit 0
    fi

    read -r state suffix netname host ips online total exitname <<<"$(
      printf '%s' "$raw" | jq -r '
        [ (.BackendState // "NoState"),
          (.CurrentTailnet.MagicDNSSuffix // "-"),
          (.CurrentTailnet.Name // "-"),
          (.Self.DNSName // "-" | split(".")[0]),
          ((.Self.TailscaleIPs // []) | join(",") | if . == "" then "-" else . end),
          ([ .Peer // {} | .[] | select(.Online) ] | length),
          ([ .Peer // {} | .[] ] | length),
          ([ .Peer // {} | .[] | select(.ExitNode) | .DNSName | split(".")[0] ] | .[0] // "-")
        ] | @tsv' | tr '\t' ' '
    )"

    # Nickname is the nicest label but needs the privileged list; fall back to
    # the tailnet name so the bar still reads sensibly without it.
    plist="$(profiles_json 2>/dev/null)"
    nick="$(printf '%s' "$plist" | jq -r '.[] | select(.selected) | .nickname // ""' 2>/dev/null)"
    label="$(label_for "$nick" "$netname")"
    others="$(printf '%s' "$plist" | jq -r '[ .[] | select(.selected | not) | .nickname ] | join(", ")' 2>/dev/null)"

    case "$state" in
      Running)    class=up ;;
      Stopped)    class=stopped ;;
      NeedsLogin) class=needslogin ;;
      *)          class=error ;;
    esac

    # The logo is drawn by CSS (background-image on #custom-tailscale). The label
    # carries text only -- and must never be empty, because waybar hides a custom
    # module with no text, which would take the logo with it.
    text="$label"

    jq -nc --arg text "$text" --arg class "$class" --arg label "$label" \
           --arg state "$state" --arg suffix "$suffix" --arg netname "$netname" \
           --arg host "$host" --arg ips "${ips//,/  }" --arg others "$others" \
           --arg online "$online" --arg total "$total" --arg exitname "$exitname" '
      def esc: tostring | gsub("&";"&amp;") | gsub("<";"&lt;") | gsub(">";"&gt;");
      { text: $text, class: $class, alt: $class,
        tooltip: ( "<b>" + ($label|esc) + "</b>   " + ($state|esc)
          + "\nTailnet    " + ($netname|esc) + "   " + ($suffix|esc)
          + "\nThis host  " + ($host|esc) + "   " + ($ips|esc)
          + "\nExit node  " + (if $exitname == "-" then "none" else ($exitname|esc) end)
          + "\nPeers      " + $online + " online of " + $total
          + (if $others == "" then "" else "\nOther      " + ($others|esc) end)
          + "\n\nClick to switch profile, right-click to toggle" ) }'
    ;;
esac
