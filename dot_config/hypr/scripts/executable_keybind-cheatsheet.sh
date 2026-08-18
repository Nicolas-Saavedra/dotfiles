#!/usr/bin/env bash
# Searchable cheatsheet of all Hyprland keybinds (Super+K), rendered in walker's
# dmenu mode. Parses conf/keybinding.conf, so it stays current automatically.
# Trailing # comments are kept as searchable descriptions.
set -uo pipefail

CONF="$HOME/.config/hypr/conf/keybinding.conf"

grep -E '^bind[a-z]*[[:space:]]*=' "$CONF" \
  | sed -E 's/^bind[a-z]*[[:space:]]*=[[:space:]]*//; s/\$mainMod/SUPER/g' \
  | awk -F',' '{
      desc = "";
      if (match($0, /#[[:space:]]*/)) {
        desc = substr($0, RSTART); sub(/^#[[:space:]]*/, "", desc);
        $0 = substr($0, 1, RSTART - 1);
      }
      n = split($0, f, ",");
      mods = f[1]; key = f[2]; act = "";
      for (i = 3; i <= n; i++) act = act f[i] (i < n ? "," : "");
      gsub(/^[ \t]+|[ \t]+$/, "", mods); gsub(/^[ \t]+|[ \t]+$/, "", key);
      gsub(/^[ \t]+|[ \t]+$/, "", act);  gsub(/^[ \t]+|[ \t]+$/, "", desc);
      # prettify Hyprland key names
      sub(/^PERIOD$/, ".", key);      sub(/^COMMA$/, ",", key);
      sub(/^Return$/, "Enter", key);  sub(/^mouse:272$/, "LeftClick", key);
      sub(/^mouse:273$/, "RightClick", key);
      sub(/^mouse_down$/, "ScrollDown", key); sub(/^mouse_up$/, "ScrollUp", key);
      combo = (mods == "" ? key : mods " + " key);
      printf "%-26s %s\n", combo, (desc != "" ? desc : act)
    }' \
  | walker -d -p "Keybinds" >/dev/null
