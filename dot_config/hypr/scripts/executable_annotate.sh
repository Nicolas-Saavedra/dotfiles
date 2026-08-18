#!/usr/bin/env bash
# Region screenshot piped into satty for annotation (arrows/text/blur/crop).
# Result lands on the clipboard and in ~/Pictures/Screenshots.
set -euo pipefail

OUT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$OUT_DIR"

REGION="$(slurp)" || exit 0
grim -g "$REGION" - | satty --filename - \
  --output-filename "$OUT_DIR/annotated-$(date +%Y-%m-%d_%H-%M-%S).png" \
  --early-exit \
  --copy-command wl-copy
