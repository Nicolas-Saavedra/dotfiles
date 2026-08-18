#!/usr/bin/env bash
# Brightness up/down for the focused monitor. Internal panel goes through
# swayosd (backlight + OSD); external displays (Odyssey G5) go through
# DDC/CI via ddcutil, which has no backlight device.
# Usage: brightness.sh up|down
set -uo pipefail

DIR="${1:-up}"
MON="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')"

if [ "$MON" = "eDP-1" ]; then
  if [ "$DIR" = "up" ]; then
    swayosd-client --brightness raise
  else
    swayosd-client --brightness lower
  fi
else
  # --noverify skips the read-back round-trip; DDC is slow enough as it is
  if [ "$DIR" = "up" ]; then
    ddcutil setvcp 10 + 10 --noverify
  else
    ddcutil setvcp 10 - 10 --noverify
  fi
fi
