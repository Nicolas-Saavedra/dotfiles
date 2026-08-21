#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Walker popup to enable/disable wallpapers in the rotation.
#
# Lists every image in ~/Pictures/Wallpapers by its flavorful name (from
# wallpaper-meta.json; falls back to the filename without extension) with a
# [x]/[ ] marker showing rotation membership. Enter toggles the highlighted
# entry; the menu reopens so you can flip several, Esc to finish. Enabling an
# entry also previews it immediately. Bound to SUPER+B.
# ─────────────────────────────────────────────────────────────────────────────

source "$HOME/.config/hypr/scripts/wallpaper-lib.sh"
LISTFILE="${WALLPAPER_LIST:-$HOME/.config/hypr/wallpaper-rotation.list}"
STATEFILE="${WALLPAPER_STATE:-$HOME/.local/state/hypr/wallpaper-current}"

touch "$LISTFILE"
mkdir -p "$(dirname "$STATEFILE")"

is_enabled() { grep -qxF "$1" "$LISTFILE"; }

build_menu() {
  local b
  while IFS= read -r b; do
    if is_enabled "$b"; then echo "[x] $(label_for "$b")"; else echo "[ ] $(label_for "$b")"; fi
  done < <(list_wallpapers)
}

while true; do
  choice="$(build_menu | walker --dmenu \
    --placeholder 'Wallpaper rotation — Enter toggles, Esc done' 2>/dev/null)"
  [ -z "$choice" ] && break                  # Esc / empty -> done

  name="$(file_for_label "${choice:4}")"     # drop "[x] "/"[ ] ", map label -> file
  [ -n "$name" ] && [ -f "$WALLDIR/$name" ] || continue

  if is_enabled "$name"; then
    # Disable: drop it from the list.
    grep -vxF "$name" "$LISTFILE" > "$LISTFILE.tmp" && mv "$LISTFILE.tmp" "$LISTFILE"
  else
    # Enable: add to the list, preview it now (with a flavor notification).
    printf '%s\n' "$name" >> "$LISTFILE"
    WALLPAPER_STATE="$STATEFILE" WALLPAPER_NOTIFY=1 \
      "$HOME/.config/hypr/scripts/wallpaper-apply.sh" "$WALLDIR/$name"
  fi
done
