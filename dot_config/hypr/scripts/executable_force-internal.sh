#!/usr/bin/env bash
# Force the internal panel (eDP-1) back on, escalating through several recovery
# methods. Re-enabling a previously-`disable`d panel from a ZERO-monitor state
# (the instant after the external is unplugged) silently fails to modeset on
# Hyprland's aquamarine backend, even though the same `keyword monitor` works
# fine when another output is still live. A single command therefore isn't
# enough, so we try progressively harder methods and stop at the first that
# actually brings eDP-1 up, logging which one won.
#
# Used by:
#   - scripts/external-monitor-primary.sh  (fallback when it sees 0 monitors)
#   - SUPER+SHIFT+M keybind                 (manual escape hatch)
#
# Exits 0 as soon as eDP-1 is enabled, 1 if every method failed.

set -u

INT="eDP-1"
LOG="${XDG_RUNTIME_DIR:-/tmp}/external-monitor-primary.log"

log() { printf '%s [force-internal] %s\n' "$(date '+%H:%M:%S')" "$*" >>"$LOG" 2>/dev/null || true; }

is_enabled() {
    hyprctl monitors -j 2>/dev/null \
        | jq -e --arg n "$1" 'any(.[]; .name == $n)' >/dev/null
}

# Escalation ladder. Each entry is passed straight to `hyprctl` (word-split on
# spaces; the monitor spec has no spaces so it stays one arg). After each we
# also force DPMS on in case the panel comes back powered-down, then re-check.
methods=(
    "keyword monitor $INT,preferred,0x0,1"
    "reload"
    "keyword monitor $INT,highres,0x0,1"
    "keyword monitor $INT,preferred,0x0,1"
)

for m in "${methods[@]}"; do
    # shellcheck disable=SC2086
    hyprctl $m >/dev/null 2>&1
    hyprctl dispatch dpms on "$INT" >/dev/null 2>&1 || true
    sleep 0.4
    if is_enabled "$INT"; then
        log "'$m' brought $INT up"
        exit 0
    fi
    log "'$m' failed ($INT still off)"
done

log "ALL recovery methods failed, $INT still down"
exit 1
