#!/usr/bin/env bash
# Prompt for a Linear ticket or a blinka-banking PR and open it in the browser.
#   ENG-123, eng123, eng 123  -> Linear issue
#   123, #123                 -> GitHub PR
set -uo pipefail

LINEAR_WORKSPACE="blinkatech"
GITHUB_REPO="Blinka-Tech/blinka-banking"

INPUT="$(walker --dmenu --inputonly --placeholder 'ENG-123 → Linear · 123 → PR' </dev/null)" || exit 0
INPUT="${INPUT//[[:space:]]/}"
[ -n "$INPUT" ] || exit 0

if [[ "$INPUT" =~ ^#?([0-9]+)$ ]]; then
  URL="https://github.com/$GITHUB_REPO/pull/${BASH_REMATCH[1]}"
elif [[ "$INPUT" =~ ^([A-Za-z]+)-?([0-9]+)$ ]]; then
  URL="https://linear.app/$LINEAR_WORKSPACE/issue/${BASH_REMATCH[1]^^}-${BASH_REMATCH[2]}"
else
  notify-send "Open ticket" "Didn't recognise \"$INPUT\""
  exit 1
fi

xdg-open "$URL" >/dev/null 2>&1 &
