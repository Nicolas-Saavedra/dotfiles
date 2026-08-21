#!/usr/bin/env bash
# Waybar mishandles monitor hotplug: when a display is added or removed it can
# leave the bar missing on an output, stuck on the wrong one, or crash. This
# listens on Hyprland's event socket and restarts the waybar systemd user
# service whenever the monitor set changes, so the bar is rebuilt cleanly.
#
# A dock/undock emits several events in quick succession, so we debounce: after
# the first monitor event we swallow the rest of the burst and restart just once
# the layout has been quiet for a moment.
#
# NOTE: crash recovery is NOT handled here — that is the service's own
# Restart=on-failure. This script only handles the screen-shift case.

set -u

reload_waybar() { systemctl --user restart waybar.service; }

: "${XDG_RUNTIME_DIR:?XDG_RUNTIME_DIR unset}"
: "${HYPRLAND_INSTANCE_SIGNATURE:?Hyprland not running}"

SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
[ -S "$SOCK" ] || { echo "Hyprland event socket not found: $SOCK" >&2; exit 1; }

# --recv-only keeps ncat alive under exec-once/nohup (see notes in the other
# monitor listeners).
while IFS= read -r line; do
    case "$line" in
        monitoradded*|monitorremoved*)
            # Debounce: drain the rest of the hotplug burst, restart after ~1s quiet.
            while IFS= read -r -t 1 _; do :; done
            reload_waybar
            ;;
    esac
done < <(ncat --recv-only -U "$SOCK")
