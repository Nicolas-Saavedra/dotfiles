#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Apply a wallpaper via awww (swww fork) with an animated transition, and record
# it as the rotation cursor (STATEFILE). Single source of truth for the
# transition look — called by wallpaper-rotate.sh, wallpaper-set.sh and
# wallpaper-menu.sh.
#
#   wallpaper-apply.sh /abs/path.jpg
#
# Transition is tunable via env (defaults in brackets):
#   WALLPAPER_TRANSITION          [grow]    type: simple|fade|left|right|top|
#                                           bottom|wipe|grow|random|none
#   WALLPAPER_TRANSITION_POS      [center]  origin for grow/wipe (alias or x,y)
#   WALLPAPER_TRANSITION_FPS      [60]
#   WALLPAPER_TRANSITION_DURATION [1.5]     seconds
# ─────────────────────────────────────────────────────────────────────────────

WALLPAPER_STATE="${WALLPAPER_STATE:-$HOME/.local/state/hypr/wallpaper-current}"

[ -n "$1" ] || exit 0
[ -f "$1" ] || { echo "wallpaper-apply: no such file: $1" >&2; exit 1; }

mkdir -p "$(dirname "$WALLPAPER_STATE")"

awww img "$1" \
  --transition-type "${WALLPAPER_TRANSITION:-grow}" \
  --transition-pos "${WALLPAPER_TRANSITION_POS:-center}" \
  --transition-fps "${WALLPAPER_TRANSITION_FPS:-60}" \
  --transition-duration "${WALLPAPER_TRANSITION_DURATION:-1.5}" \
  >/dev/null 2>&1 || exit 1

printf '%s\n' "$1" > "$WALLPAPER_STATE"

# Flavor notification for interactive picks (set via WALLPAPER_NOTIFY by the
# menu/set scripts; the timed rotation leaves it unset, so it stays silent).
if [ -n "$WALLPAPER_NOTIFY" ] && command -v notify-send >/dev/null 2>&1; then
  source "$HOME/.config/hypr/scripts/wallpaper-lib.sh"
  b="$(basename "$1")"
  notify-send -a Wallpaper "$(label_for "$b")" "$(desc_for "$b")"
fi
