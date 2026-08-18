#!/usr/bin/env bash
# Omarchy-style 3-pane layout for herdr, mirroring the tmux prefix+3 macro:
# left editor, top-right agent, short bottom runtime. Run from a single pane.
set -uo pipefail

if [ "$(herdr pane layout 2>/dev/null | grep -c 'pane')" -gt 1 ] 2>/dev/null; then
  : # best-effort; herdr layout output format may vary — split anyway is harmless
fi

herdr pane split --current --direction down --ratio 0.8
herdr pane focus --direction up
herdr pane split --current --direction right --ratio 0.65
herdr pane focus --direction left
