#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Paint the current wallpaper onto any output awww is showing a plain colour on.
#
# awww only draws on the outputs that exist when `awww img` runs, so a monitor
# hotplugged (or re-enabled) after the last rotation stays black until the next
# one — up to WALLPAPER_INTERVAL. external-monitor-primary.sh calls this on
# every monitor event. The new output can take a moment to reach awww-daemon,
# so retry briefly until no output is left bare.
# ─────────────────────────────────────────────────────────────────────────────

STATEFILE="${WALLPAPER_STATE:-$HOME/.local/state/hypr/wallpaper-current}"

cur="$(cat "$STATEFILE" 2>/dev/null)"
[ -f "$cur" ] || exit 0

for _ in 1 2 3 4 5; do
  # `awww query` lines look like ": DP-2: 1920x1200, scale: 1, currently displaying: color: 000000"
  bare="$(awww query 2>/dev/null | sed -n 's/^: \([^:]*\): .*currently displaying: color:.*/\1/p' | paste -sd,)"
  if [ -n "$bare" ]; then
    awww img "$cur" -o "$bare" --transition-type fade --transition-duration 0.5 >/dev/null 2>&1
  fi
  sleep 1
  awww query 2>/dev/null | grep -q 'currently displaying: color:' || exit 0
done
