#!/usr/bin/env bash
# Select a screen region, OCR it with tesseract, put the text on the clipboard.
set -uo pipefail

REGION="$(slurp)" || exit 0
TXT="$(grim -g "$REGION" - | tesseract stdin stdout -l eng 2>/dev/null)"

if [ -n "${TXT//[[:space:]]/}" ]; then
  printf '%s' "$TXT" | wl-copy
  notify-send "Text extracted" "$(printf '%s' "$TXT" | head -c 200)"
else
  notify-send "Text extraction" "No text found in selection"
fi
