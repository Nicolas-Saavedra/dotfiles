--  █████╗ ██╗   ██╗████████╗ ██████╗ ███████╗████████╗ █████╗ ██████╗ ████████╗
-- ██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝
-- ███████║██║   ██║   ██║   ██║   ██║███████╗   ██║   ███████║██████╔╝   ██║
-- ██╔══██║██║   ██║   ██║   ██║   ██║╚════██║   ██║   ██╔══██║██╔══██╗   ██║
-- ██║  ██║╚██████╔╝   ██║   ╚██████╔╝███████║   ██║   ██║  ██║██║  ██║   ██║
-- ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
--
-- Session daemons, started once per Hyprland start (hyprlang's `exec-once`).
--
-- Started elsewhere, so not listed here:
--   - waybar and swayosd-server run as systemd user services (waybar.service,
--     swayosd.service, under graphical-session.target) so they auto-restart on
--     crash. swayosd is also restarted after resume via after_sleep_cmd in
--     hypridle.conf: the server survives a suspend but silently stops applying
--     volume/brightness changes, which breaks the F1-F6 media keys.
--   - eDP-1's lid/dock state on start and reload: conf/monitors.lua.
--
-- Nothing here runs at the top level: top-level code also runs under
-- `Hyprland --verify-config` (dev/preflight.sh), which must not
-- start a second copy of the session.

local ctx = require("lib.context")

-- A sandbox instance shares the user's D-Bus and systemd session; starting these
-- there would steal swaync/walker/fcitx5 from the real session and repoint the
-- systemd WAYLAND_DISPLAY at the nested compositor.
if ctx.sandbox then return end

local s = ctx.scripts
local exported = table.concat(require("conf.environment").names, " ")

hl.on("hyprland.start", function()
    -- Hotplug listeners on the Hyprland event socket.
    hl.exec_cmd(s .. "/waybar-monitor-reload.sh")     -- restart waybar when the monitor set changes
    hl.exec_cmd(s .. "/external-monitor-inhibit.sh")  -- block sleep while an external is connected
    hl.exec_cmd(s .. "/external-monitor-primary.sh")  -- external-only when docked (see conf/monitors.lua)

    -- Notifications and wallpaper.
    hl.exec_cmd("swaync")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd(s .. "/wallpaper-rotate.sh")

    -- Input method (its env vars are in conf/environment.lua).
    hl.exec_cmd("fcitx5")

    -- Portals (screen sharing, file dialogs) and other D-Bus-activated apps need
    -- the session's display, plus everything conf/environment.lua sets.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP " .. exported)

    -- Clipboard history (browsed with Super+V through walker).
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Launcher service, so Super+W opens instantly.
    hl.exec_cmd("walker --gapplication-service")
end)
