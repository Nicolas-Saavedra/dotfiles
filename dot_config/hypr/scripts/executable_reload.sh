#!/usr/bin/env sh

if grep -q closed /proc/acpi/button/lid/*/state; then
  hyprctl keyword monitor "eDP-1, disable"
else
  hyprctl keyword monitor "eDP-1, preferred, auto, 1"
fi
