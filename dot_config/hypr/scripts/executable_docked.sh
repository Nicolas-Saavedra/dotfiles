#!/usr/bin/env bash
# Exit 0 when any external (non-eDP-1) monitor is enabled, 1 otherwise.
# Used by hypridle.conf to skip lock / DPMS-off / suspend while docked
# (the screensaver still runs). Same check as external-monitor-*.sh.
hyprctl monitors -j 2>/dev/null \
    | jq -e '[.[] | select(.name != "eDP-1")] | length > 0' >/dev/null
