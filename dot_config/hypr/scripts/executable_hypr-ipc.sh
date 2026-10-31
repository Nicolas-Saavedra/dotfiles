#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Shell helpers for Hyprland's Lua IPC. Sourced by lid.sh, force-internal.sh,
# external-monitor-primary.sh, dpms.sh and ~/.local/bin/screensaver-{launch,run}.
#
# Under the Lua config `hyprctl keyword` refuses to run ("keyword can't work with
# non-legacy parsers. Use eval."), and `hyprctl dispatch X` evaluates
# `hl.dispatch(X)`, so X is a Lua dispatcher expression:
#   hyprctl dispatch 'hl.dsp.focus({ workspace = "e+1" })'
# Arbitrary Lua runs with `hyprctl eval '<code>'` ("ok" or the error) and
# `hyprctl repl '<expr>'` (prints the result). These helpers cover the cases
# that need building up from shell values.
# ─────────────────────────────────────────────────────────────────────────────

# hypr_monitor "<output>, disable" | "<output>, <mode>, <position>, <scale>"
# e.g. "eDP-1, disable" or "eDP-1, preferred, 0x0, 1" — the compact rule form
# callers already use; applied as hl.monitor({...}).
hypr_monitor() {
  local -a f
  local i
  IFS=, read -ra f <<<"$1"
  for i in "${!f[@]}"; do
    f[i]="${f[i]#"${f[i]%%[![:space:]]*}"}"
    f[i]="${f[i]%"${f[i]##*[![:space:]]}"}"
  done

  if [ "${f[1]:-}" = disable ]; then
    hyprctl eval "hl.monitor({ output = \"${f[0]}\", disabled = true })"
  else
    hyprctl eval "hl.monitor({ output = \"${f[0]}\", mode = \"${f[1]:-preferred}\", position = \"${f[2]:-auto}\", scale = \"${f[3]:-1}\" })"
  fi
}

# hypr_dpms on|off|toggle [monitor]. A bare string passed to hl.dsp.dpms() is
# silently read as "toggle", so the action always goes in the table.
hypr_dpms() {
  if [ -n "${2:-}" ]; then
    hyprctl dispatch "hl.dsp.dpms({ action = \"$1\", monitor = \"$2\" })"
  else
    hyprctl dispatch "hl.dsp.dpms({ action = \"$1\" })"
  fi
}

# hypr_exec <command> [args...] — run a command through Hyprland (so the window
# opens where Hyprland would put it), not as a child of the calling script.
# Each argument is shell-quoted, so arguments with spaces survive.
hypr_exec() {
  local cmd
  printf -v cmd '%q ' "$@"
  hyprctl dispatch "hl.dsp.exec_cmd([==[${cmd% }]==])"
}

# hypr_option <section:key> <value> — change a config option at runtime, e.g.
# `hypr_option cursor:invisible true`. Gone again after the next reload.
hypr_option() {
  local value="$2" open="" close="" part
  case "$value" in
    true|false|-[0-9]*|[0-9]*) ;;
    *) value="\"$value\"" ;;
  esac
  local -a path
  IFS=: read -ra path <<<"$1"
  for part in "${path[@]}"; do
    open+="$part = { "
    close+=" }"
  done
  # The leaf is a value, not a table: drop the last "{ " / " }" pair.
  hyprctl eval "hl.config({ ${open%"{ "}$value${close% \}} })"
}
