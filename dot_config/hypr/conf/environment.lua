-- ███████╗███╗   ██╗██╗   ██╗██╗██████╗  ██████╗ ███╗   ██╗███╗   ███╗███████╗███╗   ██╗████████╗
-- ██╔════╝████╗  ██║██║   ██║██║██╔══██╗██╔═══██╗████╗  ██║████╗ ████║██╔════╝████╗  ██║╚══██╔══╝
-- █████╗  ██╔██╗ ██║██║   ██║██║██████╔╝██║   ██║██╔██╗ ██║██╔████╔██║█████╗  ██╔██╗ ██║   ██║
-- ██╔══╝  ██║╚██╗██║╚██╗ ██╔╝██║██╔══██╗██║   ██║██║╚██╗██║██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║
-- ███████╗██║ ╚████║ ╚████╔╝ ██║██║  ██║╚██████╔╝██║ ╚████║██║ ╚═╝ ██║███████╗██║ ╚████║   ██║
-- ╚══════╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝
--
-- Applied at startup only (a reload does not re-export them). hl.env only
-- reaches Hyprland's own children; conf/autostart.lua exports every name set
-- here to the systemd/D-Bus activation environment too, so D-Bus-activated
-- apps (swaync, portal file dialogs) get the same cursor, Qt and IM settings.
-- (hyprlang's `env` did not do that either; only `envd` did.)
--
-- Not set, because something else already does: XDG_SESSION_TYPE / _DESKTOP
-- (the display manager) and XDG_CURRENT_DESKTOP (Hyprland).

local M = { names = {} }

local function env(name, value)
    hl.env(name, value)
    M.names[#M.names + 1] = name
end

-- Cursor
env("XCURSOR_SIZE",     "24")
env("XCURSOR_THEME",    "catppuccin-mocha-dark-cursors")
env("HYPRCURSOR_SIZE",  "24")
env("HYPRCURSOR_THEME", "catppuccin-mocha-dark-cursors")

-- Qt: theme from qt6ct; no client-side title bars on native Wayland Qt windows,
-- which a tiling compositor has no use for.
env("QT_QPA_PLATFORMTHEME",                "qt6ct")
env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")

-- Java AWT/Swing apps render blank grey windows on non-reparenting WMs without this.
env("_JAVA_AWT_WM_NONREPARENTING", "1")

-- Deliberately not set:
--   QT_QPA_PLATFORM  Qt 6 already picks Wayland. The only Qt 5 app is VLC 3, which
--                    cannot embed video under Qt-Wayland and stays on XWayland.
--   ELECTRON_OZONE_PLATFORM_HINT  Every Electron here (Slack, Obsidian, VS Code) is
--                    38+, which already defaults to "auto".
--   GDK_BACKEND      GTK 3/4 already prefer Wayland; forcing it breaks X11-only GTK apps.
--   SDL_VIDEODRIVER  Steam games bundle their own (older) SDL, which may not
--                    have a Wayland driver at all.

-- Input method (fcitx5)
-- Unset on Wayland: GTK uses the wayland text-input protocol instead (fcitx5 diagnose)
-- env("GTK_IM_MODULE", "fcitx5")
-- env("QT_IM_MODULE",  "fcitx5")
env("XMODIFIERS",    "@im=fcitx5")
env("INPUT_METHOD",  "fcitx5")
env("SDL_IM_MODULE", "fcitx5")

return M
