#!/usr/bin/env bash
# Searchable cheatsheet of all Hyprland keybinds (Super+K), rendered in walker's
# dmenu mode. Parses conf/keybinding.conf, so it stays current automatically.
set -uo pipefail

CONF="$HOME/.config/hypr/conf/keybinding.conf"

grep -E '^bind[a-z]*\s*=' "$CONF" \
  | sed -E 's/^bind[a-z]*\s*=\s*//; s/\$mainMod/SUPER/g; s/#.*$//' \
  | awk -F',' '{
      mods=$1; key=$2; act="";
      for (i=3; i<=NF; i++) act = act $i (i<NF ? "," : "");
      gsub(/^[ \t]+|[ \t]+$/, "", mods);
      gsub(/^[ \t]+|[ \t]+$/, "", key);
      gsub(/^[ \t]+|[ \t]+$/, "", act);
      printf "%-24s %s\n", (mods=="" ? key : mods " + " key), act
    }' \
  | walker -d -p "Keybinds" >/dev/null
