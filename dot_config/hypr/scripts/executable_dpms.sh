#!/usr/bin/env bash
# dpms.sh on|off|toggle [monitor] — display power for hypridle.conf, which cannot
# build the Lua dispatcher expression itself.
. "$(dirname "$0")/hypr-ipc.sh"
hypr_dpms "$@"
