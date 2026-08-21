# Omarchy-Inspired Refinement — 2026-08-18

Session: compared this setup against Omarchy 4.0.0 "Quattro" (2026-08-14), grilled
through 9 decision branches, adopted the winners. Reference: omarchy.org/changelog.

## Decisions

| Branch | Decision |
|---|---|
| Snapshots | snap-pac (pre/post pacman on root) + hourly timeline on /home only (12h/7d/2w retention) |
| Firewall | ufw deny-incoming; trust `tailscale0`; 53317 tcp+udp for LocalSend; Docker bypass accepted |
| Power | power-profiles-daemon + waybar module (TLP rejected; sysfs charge-threshold unit still possible later) |
| Launcher | Walker/elephant absorbs clipboard (Super+V) + emoji (Super+.); rofi/wofi removed |
| Capture | satty annotate (Super+Shift+A), tesseract OCR (Super+Ctrl+S), gpu-screen-recorder toggle (Super+Shift+R); QR skipped |
| Agents | Herdr trial alongside tmux (tmux config untouched) |
| Sudo auth | pam_fprintd `timeout=10 max-tries=1` — short timeout because of past 20s lid-closed hangs |
| Updates | topgrade (`up` alias), config in ~/.config/topgrade.toml; chezmoi step included |
| Extras | swayosd OSD, ddcutil for Odyssey G5, Super+K cheatsheet, transcode.sh; weather/web2app skipped |
| Quickshell | Watch-list only — waybar+swaync stay until the plugin ecosystem matures |

## New keybinds

| Bind | Action |
|---|---|
| Super+Shift+A | Region screenshot → satty annotation → clipboard + ~/Pictures/Screenshots |
| Super+Ctrl+S | Region OCR → text on clipboard |
| Super+Shift+R | Toggle quick recording of focused monitor → ~/Videos/Recordings |
| Super+K | Searchable keybind cheatsheet (walker dmenu) |
| Super+grave | Drop-down herdr console (Omarchy qconsole port, 2026-08-21): special:scratchpad, top half of focused monitor via scripts/scratchpad-toggle.sh |
| Super+Shift+grave | Move focused window into the drop-down console |
| Super+V | Clipboard history via walker (was rofi) |
| Super+. | Emoji via walker symbols (was rofi) |
| XF86 volume/brightness | Now through swayosd (OSD overlay); brightness auto-routes to ddcutil on external monitors |

## Incident note (2026-08-18)

First ufw enable blackholed the network: kernel 7.1.8 was installed 2026-08-17 without a
reboot, so the running 7.0.14-zen had no modules on disk and ufw's exception chains failed
to load while deny-all applied. Recovered by flushing iptables. Rule going forward: never
enable a firewall (or modprobe anything) when `/lib/modules/$(uname -r)` doesn't exist.

## Known issues found during the session (2026-08-18)

1. **Config reloads bounce eDP-1 while docked.** Hyprland auto-reloads on any config save;
   reload re-runs the `exec = reload.sh` line, which re-disables eDP-1 after monitors.conf
   re-enabled it. The output bounce can destroy client surfaces (killed two Ghostty windows).
   Proposed fix: make reload.sh state-aware (query `hyprctl monitors` and only issue the
   keyword when the state actually differs), or set `misc:disable_autoreload = true` and
   reload manually. Not applied yet — edit + reload while docked is itself the hazard.
2. **XWayland lazy-spawn is broken.** The `:1` socket exists but no Xwayland process spawns
   on connect, so every X11 client (Steam, gpu-screen-recorder before the fix, `xset`) hangs
   forever in connect(). No spawn attempt appears in the Hyprland log. Recheck after the next
   Hyprland restart; if it persists, consider `xwayland { enabled = true }` explicitly or an
   upstream issue against 0.56.2. record-toggle.sh works around it with `env -u DISPLAY`.
3. **Hyprland warns .conf format is deprecated** — accelerating the existing `lua-migration`
   branch is now worth prioritizing (Omarchy 4.0 made the same move).

## Rollback / revert commands

- **Snapshots off**: `sudo systemctl disable --now snapper-timeline.timer snapper-cleanup.timer && sudo pacman -R snap-pac`
- **Firewall off**: `sudo ufw disable`
- **Power daemon off**: `sudo systemctl disable --now power-profiles-daemon`
- **Fingerprint sudo revert**: `sudo cp /etc/pam.d/sudo.bak-omarchy-refine /etc/pam.d/sudo`
- **swayosd**: remove `exec-once = swayosd-server` from conf/autostart.conf, restore wpctl/brightnessctl binds from git history

## Btrfs rollback procedure (systemd-boot — no boot-menu snapshots)

If an update breaks the system:
1. Boot (or arch ISO + `mount /dev/<root> /mnt` + `arch-chroot`) into anything that works.
2. `snapper -c root list` — find the pre-update snapshot number N (snap-pac labels them `pacman -Syu ...`).
3. `snapper -c root undochange N..0` for surgical file-level revert, **or** full rollback:
   `snapper -c root rollback N` then reboot (works because the default subvolume is switched).
4. For /home file recovery: snapshots live under `/home/.snapshots/<N>/snapshot/` — just copy files out.

## Re-enable hyprlock fingerprint (currently commented out after past timeout pain)

Edit `/etc/pam.d/hyprlock`, uncomment and amend:
`auth sufficient pam_fprintd.so timeout=10 max-tries=1`
The short timeout avoids the old 20-second lid-closed hang.

## Herdr trial notes

Installed from AUR (v0.8.0). Evaluate for ~a week: run Claude Code/opencode sessions inside
`herdr` and see if the blocked/working/done sidebar beats plain tmux panes. Drop with
`yay -R herdr` if it doesn't earn its keep. tmux (C-s) config was not touched.

## Skipped, and why

- **QR decode, web2app, weather widget**: not wanted.
- **TLP**: chose profile-switching UX over charge thresholds. A charge-threshold-only systemd
  unit (`echo 80 > /sys/class/power_supply/BAT0/charge_control_end_threshold`) coexists fine
  with power-profiles-daemon if battery health becomes a concern.
- **mise**: existing ad-hoc runtimes cause no pain.
- **ufw-docker hardening**: brittle across docker upgrades; published dev ports stay reachable by design.
- **Quickshell migration**: revisit when omarchy's plugin ecosystem stabilizes.
