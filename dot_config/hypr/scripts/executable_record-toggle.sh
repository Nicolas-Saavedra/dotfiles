#!/usr/bin/env bash
# Toggle a lightweight screen recording of the focused monitor with
# gpu-screen-recorder (VAAPI hardware encode). First press starts, second saves.
# OBS remains the tool for heavy/streaming work.
set -uo pipefail

OUT_DIR="$HOME/Videos/Recordings"

# -f full-cmdline match: the comm name is kernel-truncated to 15 chars,
# so `pgrep -x gpu-screen-recorder` can never match
if pgrep -f 'gpu-screen-recorder -w' >/dev/null; then
  pkill -SIGINT -f 'gpu-screen-recorder -w'
  sleep 0.5
  LAST="$(ls -t "$OUT_DIR" 2>/dev/null | head -1)"
  notify-send "Recording saved" "${LAST:-unknown file}"
else
  mkdir -p "$OUT_DIR"
  MON="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')"
  OUT="$OUT_DIR/rec-$(date +%Y-%m-%d_%H-%M-%S).mp4"
  # env -u DISPLAY: gsr connects to X on startup if DISPLAY is set, and a hung
  # XWayland lazy-spawn (seen 2026-08-18) blocks it forever. KMS capture needs no X.
  env -u DISPLAY gpu-screen-recorder -w "$MON" -f 60 -a default_output -o "$OUT" >/dev/null 2>&1 &
  notify-send "Recording started" "$MON → ${OUT##*/}"
fi
