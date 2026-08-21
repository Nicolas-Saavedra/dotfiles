#!/usr/bin/env bash
# Toggle the drop-down console (Omarchy-style Quake scratchpad) on the focused monitor.
#
# The console is Hyprland's special:scratchpad workspace, sized by the gap left
# underneath it: gaps_out.bottom = (1 - SHARE) of the monitor's work area. A static
# rule would be wrong on whichever of eDP-1 / the external monitor it wasn't computed
# for, so the gap is recomputed from `hyprctl monitors` on every toggle and the
# workspace rule is rewritten in place (keyword merges rules for the same workspace).
# The rest of the rule (gapsin, border, on-created-empty seed) lives in
# conf/workspaces.conf. Bound to Super+grave in conf/keybinding.conf.

SHARE=${SCRATCHPAD_SHARE:-0.5}   # fraction of the work area the console covers, from the top

bottom=$(hyprctl monitors -j | jq --argjson share "$SHARE" '
  .[] | select(.focused)
  | ((.height / .scale) - .reserved[1] - .reserved[3]) * (1 - $share)
  | floor | if . < 0 then 0 else . end')

if [[ -n $bottom ]]; then
  hyprctl keyword workspace "special:scratchpad, gapsout:0 0 ${bottom} 0" >/dev/null
fi

hyprctl dispatch togglespecialworkspace scratchpad >/dev/null
