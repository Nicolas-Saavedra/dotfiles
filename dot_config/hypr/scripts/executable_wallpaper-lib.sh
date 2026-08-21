#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Shared helpers for mapping wallpaper files <-> flavorful display names.
#
# Sourced by wallpaper-menu.sh, wallpaper-set.sh and wallpaper-apply.sh. Names
# come from wallpaper-meta.json; anything without an entry falls back to its
# filename with the extension stripped.
# ─────────────────────────────────────────────────────────────────────────────

WALLDIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
WALLPAPER_META="${WALLPAPER_META:-$HOME/.config/hypr/wallpaper-meta.json}"

# _meta <basename> <field> -> value, or empty if no jq / no file / no entry.
_meta() {
  command -v jq >/dev/null 2>&1 || return
  [ -f "$WALLPAPER_META" ] || return
  jq -r --arg k "$1" --arg f "$2" '.[$k][$f] // empty' "$WALLPAPER_META" 2>/dev/null
}

# label_for <basename> -> flavor name, else filename without extension.
label_for() {
  local n; n="$(_meta "$1" name)"
  if [ -n "$n" ]; then printf '%s\n' "$n"; else printf '%s\n' "${1%.*}"; fi
}

# desc_for <basename> -> flavor description (may be empty).
desc_for() { _meta "$1" description; }

# list_wallpapers -> every wallpaper basename in WALLDIR, sorted.
list_wallpapers() {
  shopt -s nullglob nocaseglob
  local f
  for f in "$WALLDIR"/*.{jpg,jpeg,png,webp,bmp,gif}; do basename "$f"; done | sort
  shopt -u nullglob nocaseglob
}

# file_for_label <label> -> basename whose flavor label matches, or empty.
file_for_label() {
  local want="$1" b
  while IFS= read -r b; do
    [ "$(label_for "$b")" = "$want" ] && { printf '%s\n' "$b"; return; }
  done < <(list_wallpapers)
}
