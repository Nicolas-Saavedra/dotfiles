# dotfiles

My Linux desktop, version-controlled with [chezmoi](https://chezmoi.io). Arch + Hyprland,
Catppuccin Mocha everywhere, fish and Neovim in the terminal.

This repo is published as a **reference**, not a turnkey installer. There are no bootstrap
scripts yet — the intent is that you can read how the pieces fit together and borrow what is
useful, and that chezmoi makes applying any of it straightforward if you want to.

The setup started from [Omarchy](https://omarchy.org) and was then refined against it
piece by piece. [`OMARCHY-REFINE.md`](dot_config/hypr/OMARCHY-REFINE.md) is the decision
log: which Omarchy ideas were adopted, which were rejected and why, plus the incident
notes and rollback commands that came out of that work.

---

## The system at a glance

| Layer | What | Notes |
|---|---|---|
| Compositor | **Hyprland** | Config split into 12 files under `hypr/conf/`, one per concern |
| Bar | **Waybar** | Modules split across four `.jsonc` includes; runs as a systemd user service |
| Notifications | **SwayNC** | Notification centre + control panel, styled to match the bar |
| Launcher | **Walker** (+ elephant) | Also serves clipboard history (`Super+V`) and emoji/symbols (`Super+.`) |
| Wallpaper | **awww** | Scripted rotation with animated transitions; hyprlock has its own fixed background |
| Lock / idle | **hyprlock** + **hypridle** | |
| OSD | **swayosd** | Volume/brightness overlay; brightness routes to ddcutil on external monitors |
| Terminal | **Ghostty** | JetBrainsMono Nerd Font, 85% opacity, no decorations |
| Shell | **fish** | starship prompt, zoxide, eza; a private overlay file for anything machine-specific |
| Editor | **Neovim** | [kickstart-modular](https://github.com/dam9000/kickstart-modular.nvim) fork, 43 plugins pinned in `lazy-lock.json` |
| Multiplexer | **tmux** (daily) / **herdr** (trial) / **zellij** (kept) | herdr and zellij both mirror tmux's `Ctrl+S` prefix and keys so muscle memory transfers |
| Monitor | **btop** | All four Catppuccin flavours vendored |
| Updates | **topgrade** | `up` in fish; yay for pacman+AUR, chezmoi as a step, noisy steps disabled |
| Agents | **opencode** | Config included, with `.env` files denied to the agent at the permission layer |
| Theming | Catppuccin Mocha | GTK3, qt5ct, btop, ghostty, nvim, waybar, swaync, hyprlock all from the same palette |

Hardware this is tuned for: a Lenovo laptop, docked to a Samsung Odyssey G5. The
monitor handling is "external-only when docked" — the external becomes the sole display and
the internal panel is switched off, matched by monitor *description* rather than port so it
survives re-plugging.

## How it fits together

### Hyprland is a tree of small files

`hypr/hyprland.conf` does nothing but `source` the files in `hypr/conf/`, in a fixed order:

```
monitors → programs → autostart → environment → appearance → animation
        → layout → misc → input → keybinding → windowrule → workspaces
```

Each file owns one concern, so a change to animations never touches a keybind diff, and
`git log -- hypr/conf/keybinding.conf` is a readable history of what the keys did over time.

### Keybinds document themselves

Every `bind =` line in `keybinding.conf` carries a trailing `# comment` describing what it
does. `scripts/keybind-cheatsheet.sh` parses those comments at runtime and shows them in a
searchable Walker menu on `Super+K`. Because the cheatsheet is *derived* from the config,
it cannot drift from what is actually bound — there is no second list to keep in sync.

The most used binds, for orientation:

| Bind | Action |
|---|---|
| `Super+Return` / `Super+Shift+Return` | Terminal / terminal running herdr |
| `Super+W` | App launcher (Walker) |
| `Super+V` / `Super+.` | Clipboard history / emoji picker |
| `Super+` ` | Drop-down console on `special:scratchpad`, Quake-style |
| `Super+Shift+S` / `Super+Shift+A` | Region screenshot to file / screenshot → annotate (satty) |
| `Super+Ctrl+S` | OCR a screen region straight to the clipboard (tesseract) |
| `Super+Shift+R` | Toggle a screen recording (gpu-screen-recorder) |
| `Super+B` | Wallpaper menu |
| `Super+K` | This list, generated live |
| `Super+Shift+M` | Emergency: force the internal panel back on (blind-typeable) |

### Scripts do the glue work

`hypr/scripts/` holds small bash scripts that Hyprland calls from binds and
`autostart.conf`. They are grouped by what they do:

**Capture and keys**

| Script | Does |
|---|---|
| `annotate.sh` | Region screenshot → satty → clipboard + `~/Pictures/Screenshots` |
| `ocr.sh` | Region select → tesseract → clipboard |
| `record-toggle.sh` | gpu-screen-recorder start/stop on one bind |
| `keybind-cheatsheet.sh` | Parses `keybinding.conf` and renders the cheatsheet |
| `scratchpad-toggle.sh` | Drop-down console: recomputes the `special:scratchpad` gap from the focused monitor's work area on every toggle, so it is the top half of whichever screen has focus |
| `transcode.sh` | ffmpeg wrapper for quick re-encodes |

**Monitors and power**

| Script | Does |
|---|---|
| `external-monitor-primary.sh` | Listens on Hyprland's event socket; when any non-internal monitor is live it becomes the only display and the laptop panel turns off, with a hard fallback that forces the panel on if zero monitors are ever observed |
| `external-monitor-inhibit.sh` | Holds a `systemd-inhibit` lock while docked so lid-close doesn't suspend |
| `force-internal.sh` | Escalating recovery ladder that brings the internal panel back from a zero-monitor state; `Super+Shift+M` calls it blind |
| `waybar-monitor-reload.sh` | Debounced restart of the waybar user service on hotplug, which waybar otherwise handles badly |
| `brightness.sh` | Backlight on the laptop panel, DDC/CI (ddcutil) on externals — same keys either way |
| `lid.sh` | Lid-close handling when docked/undocked |
| `reload.sh` | Re-applies monitor state on config reload |

**Wallpaper**

| Script | Does |
|---|---|
| `wallpaper-rotate.sh` | Daemon: cycles `wallpaper-rotation.list` every 30 min via awww; `SIGUSR1` advances immediately |
| `wallpaper-apply.sh` | The one place that calls `awww img` — transition type, fps, and duration are env-tunable |
| `wallpaper-menu.sh` / `wallpaper-set.sh` | Walker pickers to toggle rotation membership (`Super+B`) or force an image now (`Super+Shift+B`) |
| `wallpaper-lib.sh` | Shared helpers; maps filenames to display names from an optional `wallpaper-meta.json` |

The monitor scripts all key off the internal panel being named `eDP-1`, which is what the
kernel calls the built-in display on essentially every laptop, so they should transfer to
other hardware unchanged. The wallpaper data files (`wallpaper-rotation.list`,
`wallpaper-meta.json`) and my actual wallpapers are not tracked; the scripts fall back to
filenames when the metadata is absent. `hyprconfig-switch.sh`, bound to
`Super+Shift+Ctrl+H`, flips to an in-progress Lua config that lives in a separate worktree
and is also not published yet.

### Waybar and SwayNC are composed, not monolithic

`waybar/config` is a three-line shim that `include`s `config.jsonc` (waybar loads `config`
first if it exists, so the shim keeps the real file's `.jsonc` extension and editor support).
`config.jsonc` defines the layout and `include`s four module files (`Modules`,
`ModulesWorkspaces`, `ModulesCustom`, `ModulesGroups`), so the bar can be rearranged
without touching module definitions. Custom modules cover a recording indicator,
Claude/agent status, Tailscale state, and a weather widget. Waybar runs as a systemd user
service rather than an `exec-once`, so it restarts itself on a crash.

### One palette, many consumers

`colors/colors.css` holds the Catppuccin Mocha palette as CSS variables, imported by the
SwayNC stylesheet. Waybar carries the same values inline in `style.css`; other tools use
their native Catppuccin ports (`btop/themes/`, `qt5ct/colors/`, the ghostty `theme =` line,
the nvim `catppuccin.lua` plugin spec), but everything resolves to the same hex values.

### Shell: public config, private overlay

`fish/config.fish` sets the editor, Go paths, a handful of aliases (`lg`, `dash`, `up`,
`edit` → `chezmoi edit`), and initialises starship and zoxide. Then it does this:

```fish
if test -f ~/.config/private/config.local.fish
    source ~/.config/private/config.local.fish
end
```

Anything machine-specific or sensitive — tokens, work-specific paths, per-host tweaks —
lives in that private file, which chezmoi ignores. The public config stays portable and
the private one never touches git.

### Neovim

A fork of kickstart-modular: `init.lua` → `lua/lazy-plugins.lua` loads the `kickstart/`
plugin specs (LSP, treesitter, telescope, blink-cmp, conform, gitsigns, …) and then my
additions in `lua/custom/plugins/` — catppuccin, oil, snacks, noice, trouble, quicker, and
language tooling for TypeScript, Tailwind, Rust and Flutter. `lazy-lock.json` pins every
plugin commit so a fresh clone reproduces the same editor.

## How chezmoi manages it

If you have not used chezmoi, the repo layout is its *source state*; filenames encode the
target path and attributes:

| In this repo | On disk | Meaning |
|---|---|---|
| `dot_config/` | `~/.config/` | `dot_` → leading dot |
| `private_fish/` | `~/.config/fish/` (mode 0700) | `private_` → owner-only permissions |
| `executable_ocr.sh` | `ocr.sh` (mode 0755) | `executable_` → +x |
| `encrypted_*` | decrypted on apply | age-encrypted; ciphertext in git |
| `.chezmoiignore` | — | Files chezmoi will never write to the home directory |

Two things about the workflow are worth noting if you copy the approach:

- **`autoCommit` + `autoPush` are on.** Editing a managed file with `chezmoi edit` or
  re-adding it with `chezmoi re-add` commits and pushes in one step, so the remote never
  lags the machine. The trade-off is that every add is public immediately — which is why
  the next point exists.
- **Two layers of leak protection.** A `gitleaks` pre-commit hook gates every commit
  (chezmoi shells out to git, so `chezmoi add` is gated too), and anything that must be
  tracked but is sensitive goes through `chezmoi add --encrypt` with
  [age](https://age-encryption.org). `~/.config/.chezmoiignore` additionally blacklists
  whole directories — browsers, keyrings, `.ssh`, `.gnupg`, `.aws`, `*.env` — so they can
  never be added by accident.

## Using this as a reference

The short version: read `hypr/conf/`, `hypr/scripts/`, and `OMARCHY-REFINE.md`, and take
what you want. Everything is plain config; nothing depends on the chezmoi tooling to be
readable.

If you do want to apply pieces with chezmoi, look before you leap:

```sh
chezmoi init https://github.com/Nicolas-Saavedra/dotfiles.git
chezmoi diff            # every change it would make to your home directory
chezmoi apply ~/.config/ghostty   # apply a single tree…
chezmoi apply           # …or everything
```

Things that will not transfer as-is:

- `hypr/conf/monitors.conf` names my external monitor by description; replace it with the
  output of `hyprctl monitors` on your machine.
- `hypr/conf/programs.conf` assumes `ghostty`, `nemo` and `zen-browser` are installed.
- The scripts assume `satty`, `tesseract`, `gpu-screen-recorder`, `ddcutil`, `swayosd`,
  `walker`, `cliphist`, `hyprshot`, `playerctl`, `awww`, `jq`, and `ncat` are on `$PATH`.
- `hypridle.conf` and `Super+Shift+L` call `~/.local/bin/screensaver-launch`, which is not
  tracked here; drop those lines or point them at your own screensaver.
- `fish/config.fish` prints `(no private config loaded)` until you create the overlay file
  or remove that block.

A package list and an install script are on the to-do list; until then the tables above are
the dependency manifest.

## Secrets

There are no tokens, keys, or account identifiers in this repository or its history — see
"How chezmoi manages it" for the guards. If you find one, please open an issue so it can be
rotated.

## License

My own configuration is MIT. Vendored components keep their upstream licenses — notably
`nvim/`, which is a kickstart-modular fork and carries its own `LICENSE.md`, and the
Catppuccin theme files under `btop/themes/` and `qt5ct/colors/`.
