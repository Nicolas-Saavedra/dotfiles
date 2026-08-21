#!/usr/bin/env bash
# External-only when docked: while any external (non-eDP-1) monitor is
# connected, make it the sole display at its native/preferred resolution and
# disable the internal eDP-1 panel. When no external is present, (re-)enable
# eDP-1 so there is ALWAYS a screen.
#
# eDP-1 is only ever disabled while an external monitor is confirmed live, so
# unplugging the external (or booting undocked) always restores the laptop
# panel — you can never end up with no display.
#
# Listens on Hyprland's event socket for monitor add/remove events and for
# config reloads (which re-apply monitors.conf and would otherwise re-enable
# eDP-1), re-syncing the layout on each. Guards every toggle against the
# current state so it converges without event churn.
#
# HOTPLUG RACE: monitorremoved fires *during* Hyprland's teardown, so an
# immediate `hyprctl monitors` read can still list the departing monitor —
# has_external() then returns a stale true and sync_state no-ops, leaving
# eDP-1 disabled with nothing to replace it (a black screen on unplug). We
# therefore (a) let Hyprland settle before reading state on each event, and
# (b) keep a hard fallback that forces eDP-1 on if we ever observe zero
# enabled monitors, whatever the cause.

set -u

INT="eDP-1"
SETTLE=0.4  # seconds to let Hyprland finish (re)configuring before we read state
LOG="${XDG_RUNTIME_DIR:-/tmp}/external-monitor-primary.log"

log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" >>"$LOG" 2>/dev/null || true; }

# Names of all currently-enabled monitors that are not the internal panel.
external_names() {
    hyprctl monitors -j 2>/dev/null \
        | jq -r '.[] | select(.name != "'"$INT"'") | .name'
}

has_external() { [ -n "$(external_names)" ]; }

# Number of currently-enabled monitors (disabled ones are absent from this list).
enabled_count() {
    hyprctl monitors -j 2>/dev/null | jq 'length' 2>/dev/null
}

# True if $1 is currently enabled (disabled monitors are absent from
# `hyprctl monitors`; they only show under `hyprctl monitors all`).
is_enabled() {
    hyprctl monitors -j 2>/dev/null \
        | jq -e --arg n "$1" 'any(.[]; .name == $n)' >/dev/null
}

HERE="$(cd "$(dirname "$0")" && pwd)"

# Bring eDP-1 back up. Delegated to force-internal.sh, which escalates through
# several recovery methods because a 0-monitor -> 1-monitor modeset can silently
# fail on the aquamarine backend (see that script for the gory details).
enable_internal() {
    "$HERE/force-internal.sh"
}

sync_state() {
    if has_external; then
        # An external is live → it becomes primary at native res. Only act on
        # the transition (while the internal panel is still on) to avoid churn.
        if is_enabled "$INT"; then
            while IFS= read -r name; do
                [ -n "$name" ] || continue
                # `auto` places it at 0,0 once eDP-1 is gone; `preferred` = native mode.
                hyprctl keyword monitor "$name,preferred,auto,1"
            done < <(external_names)
            hyprctl keyword monitor "$INT,disable"
            log "external present -> disabled $INT"
        fi
    else
        # No external → guarantee the internal panel is on.
        if ! is_enabled "$INT"; then
            enable_internal
            log "no external -> re-enabled $INT"
        fi
    fi

    # Hard guarantee: never leave the session with zero displays. If the reads
    # above raced a hotplug and nothing ended up enabled, force eDP-1 on.
    if [ "$(enabled_count)" = "0" ]; then
        enable_internal
        log "FALLBACK: zero monitors enabled -> forced $INT on"
    fi
}

: "${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR unset}"
: "${HYPRLAND_INSTANCE_SIGNATURE:?Hyprland not running}"

SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
[ -S "$SOCK" ] || { echo "Hyprland event socket not found: $SOCK" >&2; exit 1; }

sync_state

while IFS= read -r line; do
    case "$line" in
        monitoradded*|monitorremoved*|configreloaded*)
            # Let Hyprland settle so hyprctl reflects the post-hotplug reality
            # before we decide what to enable/disable. Events that arrive during
            # the sleep buffer in the pipe and are handled on the next read,
            # which also naturally debounces add/remove bursts.
            sleep "$SETTLE"
            sync_state
            ;;
    esac
done < <(ncat --recv-only -U "$SOCK")
