#!/usr/bin/env bash
# dev/preflight.sh — check the config before it goes live (safe to run anytime).
#
#   1. `Hyprland --verify-config` over hyprland.lua: no compositor is started.
#      Catches syntax errors, unknown option / rule / monitor fields and
#      animation leaves, and on 0.57+ bad dispatcher arguments in binds. Top-level
#      code and config.reloaded handlers run here too (hyprland.start ones do
#      not), so the verifier gets no Hyprland/Wayland session variables: anything
#      it spawns cannot reach the live session.
#   2. dev/test-monitors.lua, the unit test for the monitor policy.
#
# HYPRLAND_VERIFY_BIN=<path> also checks against another build, e.g. a newer one
# unpacked from /var/cache/pacman/pkg/ before upgrading to it.
# For end-to-end checks use dev/sandbox.sh.
set -u

root="$(cd "$(dirname "$0")/.." && pwd)"
failed=0

for bin in Hyprland ${HYPRLAND_VERIFY_BIN:+"$HYPRLAND_VERIFY_BIN"}; do
    printf 'verify-config with %s\n' "$("$bin" --version | head -1 | cut -d' ' -f1-2)"
    out=$(env -u HYPRLAND_INSTANCE_SIGNATURE -u WAYLAND_DISPLAY -u DISPLAY \
        timeout 30 "$bin" --verify-config -c "$root/hyprland.lua" 2>&1 \
        | sed -n '/Config parsing result/,$p' | sed '1,2d')
    if [ "$out" = "config ok" ]; then
        printf '  ok\n'
    else
        printf '%s\n' "${out:-(no result: verifier crashed or timed out)}" | sed 's/^/  /' >&2
        failed=1
    fi
done

printf 'monitor policy unit test\n'
if out=$(cd "$root" && lua dev/test-monitors.lua 2>&1); then
    printf '  ok\n'
else
    printf '%s\n' "$out" | grep -v '^ok ' | sed 's/^/  /' >&2
    failed=1
fi

[ "$failed" = 0 ] && printf '\npreflight passed.\n' || { printf '\npreflight FAILED.\n' >&2; exit 1; }
