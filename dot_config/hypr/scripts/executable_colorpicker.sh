#!/usr/bin/env bash
# Eyedropper: freeze the screen, pick a pixel with hyprpicker, put the color on
# the clipboard. The notification carries a swatch of the picked color as its
# icon, so you can confirm you hit the right pixel without pasting anywhere.
#
# Usage: colorpicker.sh [hex|rgb]   (default hex)
#
# The pick is always done in hex and converted here rather than asking
# hyprpicker for rgb directly: one code path feeds both the clipboard value and
# the swatch, and magick only understands the hex form anyway.
set -uo pipefail

FMT="${1:-hex}"

# -q quiets the startup logs, -l keeps hex lowercase (matches CSS/Tailwind).
# Cancelling with Esc exits non-zero or prints nothing, depending on version.
HEX="$(hyprpicker -q -l -f hex)" || exit 0
HEX="${HEX//[[:space:]]/}"
[ -n "$HEX" ] || exit 0

case "$FMT" in
  hex) OUT="$HEX" ;;
  rgb) OUT="rgb($((16#${HEX:1:2})), $((16#${HEX:3:2})), $((16#${HEX:5:2})))" ;;
  *)   notify-send "Color picker" "Unknown format: $FMT (use hex or rgb)"; exit 1 ;;
esac

printf '%s' "$OUT" | wl-copy

# Swatch icon. Written per-invocation because swaync caches icons by path, so a
# fixed filename would show the previous color. Stale files are swept on the
# next pick rather than on exit, which would race the daemon reading the file.
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/hypr/colorpicker"
mkdir -p "$CACHE"
find "$CACHE" -name 'swatch-*.png' -mmin +1 -delete 2>/dev/null
ICON="$CACHE/swatch-$$.png"

if magick -size 96x96 "xc:$HEX" PNG32:"$ICON" 2>/dev/null; then
  notify-send -i "$ICON" -a "Color picker" "Color copied" "$OUT"
else
  notify-send -a "Color picker" "Color copied" "$OUT"
fi
