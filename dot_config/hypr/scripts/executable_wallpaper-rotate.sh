#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Wallpaper rotation daemon for hyprpaper.
#
# Sequentially cycles through the wallpapers listed in wallpaper-rotation.list,
# swapping every $INTERVAL seconds via wallpaper-apply.sh (awww, with an
# animated transition).
#
# Started from conf/autostart.conf as an exec-once. The wallpaper menu
# (wallpaper-menu.sh) edits the list and writes the current pick to STATEFILE;
# this daemon re-reads both every tick, so menu changes take effect on the next
# rotation. Send SIGUSR1 to force an immediate advance.
# ─────────────────────────────────────────────────────────────────────────────

WALLDIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
LISTFILE="${WALLPAPER_LIST:-$HOME/.config/hypr/wallpaper-rotation.list}"
STATEFILE="${WALLPAPER_STATE:-$HOME/.local/state/hypr/wallpaper-current}"
INTERVAL="${WALLPAPER_INTERVAL:-1800}"   # 30 minutes

mkdir -p "$(dirname "$STATEFILE")"

# Populate the global `enabled` array with full paths of enabled, existing
# wallpapers, in list order.
read_enabled() {
  enabled=()
  [ -f "$LISTFILE" ] || return
  while IFS= read -r line; do
    line="${line%%#*}"                       # strip trailing comments
    line="${line#"${line%%[![:space:]]*}"}"  # ltrim
    line="${line%"${line##*[![:space:]]}"}"  # rtrim
    [ -z "$line" ] && continue
    [ -f "$WALLDIR/$line" ] && enabled+=("$WALLDIR/$line")
  done < "$LISTFILE"
}

apply() {
  [ -n "$1" ] || return
  WALLPAPER_STATE="$STATEFILE" "$HOME/.config/hypr/scripts/wallpaper-apply.sh" "$1"
}

# Advance to the wallpaper after the current one (from STATEFILE), wrapping.
tick() {
  read_enabled
  [ "${#enabled[@]}" -eq 0 ] && return
  local cur="" i idx=0
  [ -f "$STATEFILE" ] && cur="$(cat "$STATEFILE")"
  for i in "${!enabled[@]}"; do
    if [ "${enabled[$i]}" = "$cur" ]; then
      idx=$(( (i + 1) % ${#enabled[@]} ))
      break
    fi
  done
  apply "${enabled[$idx]}"
}

# Wait for the awww daemon to be ready before the first swap.
for _ in $(seq 1 30); do
  awww query >/dev/null 2>&1 && break
  sleep 1
done

# SIGUSR1 -> interrupt the current sleep and rotate now.
trap 'kill "$sleep_pid" 2>/dev/null' USR1

tick   # set the first wallpaper immediately on startup
while true; do
  sleep "$INTERVAL" & sleep_pid=$!
  wait "$sleep_pid"
  tick
done
