# Hyprland config

Hyprland's Lua config (0.56+; the only format 0.57+ can load). It replaced the
hyprlang `hyprland.conf`, which is in git history at the commit
`snapshot: live hyprlang config before the Lua cutover`. Verified on 0.56.2 and
0.57.0. The other `.conf` files here (hypridle, hyprlock, hyprpaper, mocha) belong
to those tools, which still use hyprlang.

API reference: `/usr/share/hypr/stubs/hl.meta.lua` (installed with Hyprland; point
lua-language-server at it). Wiki: <https://wiki.hypr.land/configuring/>.

## Layout

```
hyprland.lua          entry point: loads conf/* in order
lib/context.lua       shared paths (home, scripts dir) and the sandbox flag
conf/
  environment.lua     hl.env: cursor, Qt, Java, fcitx5 (and what is deliberately not set)
  monitors.lua        monitor rules as data + the internal-panel (eDP-1) policy
  autostart.lua       session daemons on hyprland.start
  appearance.lua      general/decoration options, layer rules (blur, no_anim)
  animation.lua       curves and per-leaf animations
  layout.lua          dwindle / master
  misc.lua            misc and binds options, lid switch binds
  input.lua           keyboard, mouse, touchpad, per-device overrides
  keybinding.lua      every bind, each with a description (feeds Super+K)
  windowrule.lua      window rules
  workspaces.lua      workspace -> monitor rules
  scratchpad.lua      drop-down console (special:scratchpad) and its per-monitor refit
  programs.lua        terminal / file manager / browser, returned as a table
scripts/              helpers run by binds, autostart, hypridle and waybar
dev/
  preflight.sh        Hyprland's own parser over this tree + the unit test
  sandbox.sh          run this config in a nested Hyprland window
  compare.sh          diff the effective config of two running instances
  test-monitors.lua   unit test for the monitor policy (plain `lua`)
```

Conventions:

- One concern per module. A module either configures Hyprland when required, or
  returns data (`conf.programs`, `conf.environment` lists the names it set,
  `conf.monitors` also exposes `apply_external`).
- No side effects at the top level: anything that spawns or touches the session
  goes in an `hl.on("hyprland.start", ...)` handler. Top-level code and
  `config.reloaded` handlers also run under `Hyprland --verify-config`.
- Paths come from `lib/context.lua`.
- Every bind gets a plain-language description (the cheatsheet shows it).

## Scripts and Hyprland's Lua IPC

With the Lua config, `hyprctl keyword` refuses to run, and `hyprctl dispatch X`
evaluates `hl.dispatch(X)`, so X is a Lua expression:
`hyprctl dispatch 'hl.dsp.focus({ workspace = "e+1" })'`. `hyprctl eval '<lua>'`
runs code; `hyprctl repl '<expr>'` prints a value. `scripts/hypr-ipc.sh` has shell
helpers for the cases built from shell values: `hypr_monitor "<out>, <mode>, <pos>,
<scale>"` / `"<out>, disable"`, `hypr_dpms on|off [mon]`, `hypr_exec <cmd...>`,
`hypr_option <section:key> <value>`.

Who uses what:

- `external-monitor-primary.sh` (hotplug: external-only when docked) re-applies
  monitor rules with `hyprctl eval 'require("conf.monitors").apply_external(name)'`.
  Its `EXTEND_DESCS` must match the `extend = true` entries in `conf/monitors.lua`.
- `lid.sh` (lid binds), `force-internal.sh` (Super+Shift+M), `dpms.sh` (hypridle),
  `~/.local/bin/screensaver-launch` and `screensaver-run` source `hypr-ipc.sh`.
- `keybind-cheatsheet.sh` (Super+K) reads `hyprctl binds -j`.
- waybar's `ModulesWorkspaces.jsonc` / `ModulesCustom.jsonc` call
  `hyprctl dispatch '<lua>'` directly.

## Behaviour worth knowing

- **eDP-1 at load.** `conf/monitors.lua` decides eDP-1's rule from the live dock
  and lid state, so a reload while docked leaves the panel alone (the hyprlang
  config bounced it, which could destroy client surfaces), and eDP-1 is never
  disabled unless another screen is live. Hotplug after that is the script's job.
- **Drop-down console** (Super+`): the workspace rule's bottom gap is refit to the
  focused monitor on every monitor focus/layout change; the bind toggles directly.
- **Environment:** `conf/environment.lua` explains each variable set and the
  Wayland ones deliberately left out; autostart exports all of them to the
  systemd/D-Bus activation environment so D-Bus-activated apps match.
- **Force-kill** (Super+Shift+Q) SIGTERMs the focused window's pid.

## Testing a change

1. `dev/preflight.sh` — Hyprland's own parser on this tree (with no access to the
   live session) plus `dev/test-monitors.lua`.
2. `dev/sandbox.sh` — the real thing in a nested window, without daemons or the
   monitor policy (`HYPR_SANDBOX=1`). Drive it with `hyprctl -i 1 ...`; add outputs
   with `hyprctl -i 1 output create headless`; screenshot it with
   `WAYLAND_DISPLAY=wayland-2 grim -o WAYLAND-1 out.png`.
3. `dev/compare.sh 0 1` — with the sandbox running, diffs every option, bind,
   workspace rule and animation against the live session. Expected residue: the
   scratchpad's computed bottom gap (monitor-dependent).

Careful: the sandbox's Super+` seeds herdr's real `scratch` session, and do not
`hyprctl reload` the live session (it has disconnected every client on this
setup). Saved edits are picked up by Hyprland's config watcher.

## Upgrading Hyprland

`hyprland` is pinned with `IgnorePkg` in `/etc/pacman.conf`. Before lifting it,
unpack the new package from `/var/cache/pacman/pkg/` into a scratch directory and
run `HYPRLAND_VERIFY_BIN=<dir>/usr/bin/Hyprland dev/preflight.sh` and
`HYPRLAND_BIN=<dir>/usr/bin/Hyprland dev/sandbox.sh`; diff
`/usr/share/hypr/stubs/hl.meta.lua` against the new one for API changes.
0.57.0 already passes both.
