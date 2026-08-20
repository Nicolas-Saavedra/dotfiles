# dotfiles

Hyprland on Arch, managed with [chezmoi](https://chezmoi.io). Catppuccin Mocha throughout.

Started from [Omarchy](https://omarchy.org) and refined against it deliberately rather than
by accretion — see [`OMARCHY-REFINE.md`](dot_config/hypr/OMARCHY-REFINE.md) for the decision
log, including the branches I rejected and why.

---

## What's in here

| | |
|---|---|
| **Compositor** | Hyprland — split across 12 files in `hypr/conf/` rather than one monolith |
| **Bar** | Waybar |
| **Notifications** | SwayNC |
| **Launcher** | Walker + elephant — absorbed clipboard (`Super+V`) and emoji (`Super+.`); rofi and wofi removed |
| **Terminal** | Ghostty |
| **Shell** | fish |
| **Editor** | Neovim — [kickstart-modular](https://github.com/dam9000/kickstart-modular.nvim) fork, 43 plugins pinned via `lazy-lock.json` |
| **Lock / idle** | hyprlock + hypridle |
| **Monitor** | btop |
| **Prompt** | starship |
| **Multiplexer** | tmux, with [herdr](dot_config/herdr/config.toml) on trial for agent work — keybinds mirrored from tmux so muscle memory transfers |
| **Updates** | topgrade (`up`), chezmoi included as a step |

## Custom tooling

Small scripts in [`hypr/scripts/`](dot_config/hypr/scripts), bound to keys:

| Script | Does |
|---|---|
| `annotate.sh` | Region screenshot → satty annotation → clipboard + `~/Pictures/Screenshots` |
| `ocr.sh` | Region select → tesseract → text straight to clipboard |
| `record-toggle.sh` | gpu-screen-recorder start/stop on one bind |
| `brightness.sh` | ddcutil, so an external monitor takes the same keys as the laptop panel |
| `keybind-cheatsheet.sh` | Parses `keybinding.conf` and renders it — the cheatsheet cannot drift from the actual binds |
| `lid.sh` | Lid-close handling |
| `transcode.sh` | ffmpeg wrapper |
| `reload.sh` | Reload the compositor config |

`keybind-cheatsheet.sh` is the one I'd point at: it reads the comments in `keybinding.conf`
and prettifies key names, so `Super+K` always shows what is actually bound rather than what
the documentation last remembered.

## Structure

```
dot_config/
├── hypr/          compositor, split by concern + custom scripts
│   └── conf/      monitors, programs, autostart, environment, appearance,
│                  animation, layout, misc, input, keybinding, windowrule,
│                  workspaces
├── nvim/          kickstart-modular fork
├── waybar/        bar + styling
├── private_fish/  shell config, functions, completions
├── swaync/        notification centre
├── ghostty/       terminal
├── btop/  starship/  zellij/  herdr/  qt5ct/  rofi/  colors/
└── topgrade.toml
```

`colors/` holds a single Catppuccin palette exported as both CSS and rasi, so the bar and
the launcher stay in sync from one source.

## Using these

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply Nicolas-Saavedra
```

Or to look before applying:

```sh
chezmoi init https://github.com/Nicolas-Saavedra/dotfiles.git
chezmoi diff          # what would change
chezmoi apply         # do it
```

These are tuned to my hardware — a Lenovo laptop plus an Odyssey G5 — so
`hypr/conf/monitors.conf` is the first thing you'd want to change.

## Secrets

Anything sensitive is encrypted with [age](https://age-encryption.org) via chezmoi's
`encrypted_` attribute, so ciphertext is all that ever reaches this repo. A `gitleaks`
pre-commit hook blocks credentials from being committed at all — the repo is public, and a
leak here means rotating credentials rather than reverting a file.

Consequently there are no tokens, keys, or account identifiers in this history. If you find
one, please open an issue.

## License

MIT for my own configuration. Vendored components keep their upstream licenses — notably
`nvim/`, which is a kickstart-modular fork and carries its own `LICENSE.md`.
