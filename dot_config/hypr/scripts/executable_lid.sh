#!/usr/bin/env sh

has_external_monitor() {
  hyprctl monitors | grep '^Monitor ' | grep -vq '^Monitor eDP-1 '
}

lock_now() {
  loginctl lock-session
  pidof hyprlock >/dev/null 2>&1 || hyprlock >/dev/null 2>&1 &
}

case "${1:-}" in
  close)
    lock_now
    if has_external_monitor; then
      hyprctl keyword monitor "eDP-1, disable"
    else
      systemctl suspend
    fi
    ;;
  open)
    hyprctl keyword monitor "eDP-1, preferred, auto, 1"
    ;;
esac
