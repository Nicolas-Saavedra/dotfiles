#!/usr/bin/env bash
# dev/compare.sh <instance-a> <instance-b> — diff the effective config of two
# running Hyprland instances (indices or signatures from `hyprctl instances`).
#
# Proves a change (or another Hyprland build) behaves like what is running now:
# start dev/sandbox.sh with the changed tree or HYPRLAND_BIN, then
# `dev/compare.sh 0 1`. It was first used to prove the Lua port matched the old
# hyprland.conf, hence the hyprlang notes below. Compares
#   - every option Hyprland knows (the key list comes from the installed Lua
#     stubs), via `hyprctl getoption` (hyprlang reports bools as 1/0, Lua as
#     true/false; both are folded to 1/0)
#   - binds (keys, modifiers, flags; not dispatchers, which the Lua side
#     reports as opaque "__lua" handles)
#   - workspace rules, animations and curves
# Window and layer rules have no hyprctl dump; check those by hand.
#
# Expected differences: monitor-dependent values, and anything the sandbox
# skips on purpose (see lib/context.lua).
set -euo pipefail

a="${1:?usage: compare.sh <instance-a> <instance-b>}"
b="${2:?usage: compare.sh <instance-a> <instance-b>}"
stubs="${HYPR_STUBS:-/usr/share/hypr/stubs/hl.meta.lua}"
out="$(mktemp -d)"

# Stub keys are Lua-style (decoration.blur.passes); getoption on the hyprlang
# side only takes the colon form, where `col.` stays part of the leaf name.
keys() {
    sed -n '/^---@alias HL.ConfigKey/,/^$/p' "$stubs" \
        | sed -n 's/^---| "\(.*\)"$/\1/p' | sed 's/\./:/g; s/:col:/:col./g'
}

options() {
    local k
    while IFS= read -r k; do
        printf '%s = %s\n' "$k" "$(hyprctl -i "$1" getoption "$k" -j 2>/dev/null \
            | jq -c 'del(.option, .set) | to_entries | map(.value) | .[0]
                   | if type == "boolean" then (if . then 1 else 0 end) else . end' 2>/dev/null)"
    done < <(keys)
}

# Left out on purpose: descriptions (hyprlang has none; check the Lua side with
# `hyprctl binds -j | jq '.[] | select(.has_description | not)'`), key case
# (`f` vs `F` is the same key) and the mouse flag (0.56 does not record it for
# Lua binds; window.drag/resize end on button release by themselves).
binds() {
    hyprctl -i "$1" binds -j | jq -r '.[] | [.modmask, (.key | ascii_downcase), .locked,
        .release, .repeat, .longPress, .non_consuming] | @tsv' | sort
}

dump() {
    options "$1" >"$out/$2.options"
    binds "$1" >"$out/$2.binds"
    hyprctl -i "$1" workspacerules -j | jq -S . >"$out/$2.workspacerules"
    hyprctl -i "$1" animations -j | jq -S . >"$out/$2.animations"
}

dump "$a" a
dump "$b" b

status=0
for part in options binds workspacerules animations; do
    if diff -u "$out/a.$part" "$out/b.$part" >"$out/$part.diff"; then
        printf '%-15s identical\n' "$part"
    else
        printf '%-15s DIFFERS (%s)\n' "$part" "$out/$part.diff"
        status=1
    fi
done
exit "$status"
