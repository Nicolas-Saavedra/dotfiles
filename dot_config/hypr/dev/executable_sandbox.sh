#!/usr/bin/env bash
# dev/sandbox.sh [config.lua] — run the Lua config in a nested Hyprland window.
#
# The nested compositor is a window on the real session, with its own outputs,
# IPC socket and Xwayland, so binds, rules, workspace rules and the scratchpad
# can be exercised without logging out. HYPR_SANDBOX=1 makes the config skip
# anything session-wide (daemons, systemd/dbus environment, monitor policy; see
# lib/context.lua), so the real session's swaync/walker/waybar are left alone.
#
# Talk to it with `hyprctl -i <n>` (`hyprctl instances` lists them), e.g.
#   hyprctl -i 1 binds -j
#   hyprctl -i 1 output create headless     # add a second monitor
# Close it with `hyprctl -i 1 dispatch 'hl.dsp.exit()'`.
#
# HYPRLAND_BIN picks another build, e.g. a newer one unpacked from the pacman
# cache, to try the config against it before upgrading.
set -eu

here="$(cd "$(dirname "$0")/.." && pwd)"
config="${1:-$here/hyprland.lua}"

export HYPR_SANDBOX=1
# Anything the nested instance spawns must address it, never the real session.
unset HYPRLAND_INSTANCE_SIGNATURE

exec "${HYPRLAND_BIN:-Hyprland}" -c "$config"
