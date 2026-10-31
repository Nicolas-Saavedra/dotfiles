-- ██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗███████╗██████╗  █████╗  ██████╗███████╗███████╗
-- ██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝
-- ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ ███████╗██████╔╝███████║██║     █████╗  ███████╗
-- ██║███╗██║██║   ██║██╔══██╗██╔═██╗ ╚════██║██╔═══╝ ██╔══██║██║     ██╔══╝  ╚════██║
-- ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗███████║██║     ██║  ██║╚██████╗███████╗███████║
--  ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝╚══════╝
--
-- Single logical display: all workspaces live on eDP-1. When an external is
-- docked, the hotplug handler (scripts/external-monitor-primary.sh) disables
-- eDP-1, and Hyprland automatically relocates these workspaces onto the
-- external; they move back when it is unplugged. (If you go back to a
-- side-by-side two-monitor layout, re-split these across the external.)
--
-- The drop-down console's special:scratchpad rule lives in conf/scratchpad.lua,
-- which recomputes it per monitor.

for i = 1, 10 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1", default = (i == 1) or nil })
end

-- The "monitor workspace": what the Acer portable screen opens on when it
-- extends the desktop (see EXTEND_DESCS in scripts/external-monitor-primary.sh).
-- Waybar shows it as a monitor icon instead of "11".
hl.workspace_rule({ workspace = "11", monitor = "desc:Acer Technologies PM161W", default = true })
