#!/bin/bash

# Get active window title
title=$(hyprctl activewindow -j | jq -r '.title')

# Check for "null" or empty string
if [[ "$title" != "null" && -n "$title" ]]; then
  echo " | " # or your preferred separator
else
  echo ""
fi
