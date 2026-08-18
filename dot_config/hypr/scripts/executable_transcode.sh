#!/usr/bin/env bash
# Quick ffmpeg transcodes, Omarchy-style.
# Usage:
#   transcode.sh <file> mp4            # remux/re-encode to H.264 mp4
#   transcode.sh <file> gif            # palette-optimized GIF (max 720px wide)
#   transcode.sh <file> mp3            # extract audio
#   transcode.sh <file> trim <ss> <to> # lossless-ish cut, e.g. trim 00:10 00:35
set -euo pipefail

IN="${1:?usage: transcode.sh <file> mp4|gif|mp3|trim [start end]}"
MODE="${2:?mode required: mp4|gif|mp3|trim}"
BASE="${IN%.*}"

case "$MODE" in
  mp4)
    ffmpeg -i "$IN" -c:v libx264 -preset fast -crf 23 -c:a aac -movflags +faststart "$BASE.transcoded.mp4"
    ;;
  gif)
    ffmpeg -i "$IN" -vf "fps=15,scale=720:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" "$BASE.gif"
    ;;
  mp3)
    ffmpeg -i "$IN" -vn -q:a 2 "$BASE.mp3"
    ;;
  trim)
    SS="${3:?start time required}"; TO="${4:?end time required}"
    ffmpeg -ss "$SS" -to "$TO" -i "$IN" -c copy "$BASE.trimmed.${IN##*.}"
    ;;
  *)
    echo "unknown mode: $MODE (mp4|gif|mp3|trim)" >&2; exit 1
    ;;
esac
