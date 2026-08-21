#!/usr/bin/env bash
# Holds a systemd-inhibit lock while any external (non-eDP-1) monitor is
# connected. hypridle's listeners have ignore_inhibit=false, so this pauses
# the lock / DPMS-off / suspend timers as long as the lock is held.
#
# Listens on Hyprland's event socket for monitor add/remove events and
# re-syncs the lock state. On exit, the trap releases the lock.

set -u

INHIBIT_PID=

is_alive() { [ -n "${1-}" ] && kill -0 "$1" 2>/dev/null; }

has_external_monitor() {
    hyprctl monitors -j 2>/dev/null \
        | jq -e '[.[] | select(.name != "eDP-1")] | length > 0' >/dev/null
}

start_inhibit() {
    is_alive "$INHIBIT_PID" && return
    systemd-inhibit \
        --what=idle:sleep \
        --who=external-monitor-inhibit \
        --why="External monitor connected" \
        --mode=block \
        sleep infinity &
    INHIBIT_PID=$!
}

stop_inhibit() {
    if is_alive "$INHIBIT_PID"; then
        kill "$INHIBIT_PID" 2>/dev/null || true
        wait "$INHIBIT_PID" 2>/dev/null || true
    fi
    INHIBIT_PID=
}

sync_state() {
    if has_external_monitor; then
        start_inhibit
    else
        stop_inhibit
    fi
}

cleanup() { stop_inhibit; exit 0; }
trap cleanup INT TERM EXIT

: "${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR unset}"
: "${HYPRLAND_INSTANCE_SIGNATURE:?Hyprland not running}"

SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
[ -S "$SOCK" ] || { echo "Hyprland event socket not found: $SOCK" >&2; exit 1; }

sync_state

while IFS= read -r line; do
    case "$line" in
        monitoradded*|monitorremoved*) sync_state ;;
    esac
done < <(ncat --recv-only -U "$SOCK")
