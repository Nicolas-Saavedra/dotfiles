-- ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗
-- ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗
-- ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║
-- ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║
-- ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝
-- ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝
-- -------------------------------------------------------------------
--
-- Entry point. Each concern lives in its own module under conf/; shared paths
-- and the sandbox flag are in lib/context.lua. See README.md for the layout,
-- how the helper scripts fit in, and how to test a change safely.
--
-- API reference: /usr/share/hypr/stubs/hl.meta.lua (point lua-language-server at it).

-- Modules are required by dotted path from this directory (conf.monitors ->
-- conf/monitors.lua); Hyprland puts the config's own directory on package.path.

-- Environment first: it must be in place before anything is spawned.
require("conf.environment")

-- Outputs
require("conf.monitors")

-- Session daemons (hyprland.start only)
require("conf.autostart")

-- Look and feel
require("conf.appearance")
require("conf.animation")
require("conf.layout")
require("conf.misc")

-- Input
require("conf.input")

-- Keybindings
require("conf.keybinding")

-- Window and workspace rules
require("conf.windowrule")
require("conf.workspaces")
require("conf.scratchpad")
