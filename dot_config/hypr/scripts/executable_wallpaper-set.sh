#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Force the wallpaper to a specific image, now.
#
#   wallpaper-set.sh                       -> walker picker (flavor names)
#   wallpaper-set.sh "Scarlet Mist Lake"   -> by flavor name
#   wallpaper-set.sh touhou-lake           -> by filename (extension optional)
#   wallpaper-set.sh /abs/path.jpg         -> by absolute path
#
# Applies immediately via wallpaper-apply.sh (awww transition + flavor
# notification) and seeds the rotation cursor so the 30-min sequence continues
# after this pick. Does not change rotation membership. Bound to SUPER+SHIFT+B.
# ─────────────────────────────────────────────────────────────────────────────

source "$HOME/.config/hypr/scripts/wallpaper-lib.sh"
STATEFILE="${WALLPAPER_STATE:-$HOME/.local/state/hypr/wallpaper-current}"

# Resolve a query (path / filename / name-sans-ext / flavor name) to an abs path.
resolve() {
  local q="$1" b
  [ -z "$q" ] && return
  [ -f "$q" ] && { printf '%s\n' "$q"; return; }
  while IFS= read -r b; do
    if [ "$b" = "$q" ] || [ "${b%.*}" = "$q" ] || [ "$(label_for "$b")" = "$q" ]; then
      printf '%s\n' "$WALLDIR/$b"; return
    fi
  done < <(list_wallpapers)
}

if [ -n "$1" ]; then
  path="$(resolve "$1")"
  [ -z "$path" ] && { echo "wallpaper-set: no match for '$1'" >&2; exit 1; }
else
  choice="$(while IFS= read -r b; do label_for "$b"; done < <(list_wallpapers) \
    | walker --dmenu --placeholder 'Set wallpaper now' 2>/dev/null)"
  [ -z "$choice" ] && exit 0
  path="$(resolve "$choice")"
  [ -z "$path" ] && exit 1
fi

WALLPAPER_STATE="$STATEFILE" WALLPAPER_NOTIFY=1 \
  exec "$HOME/.config/hypr/scripts/wallpaper-apply.sh" "$path"
