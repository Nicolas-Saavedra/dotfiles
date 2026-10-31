--  █████╗ ███╗   ██╗██╗███╗   ███╗ █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
-- ██╔══██╗████╗  ██║██║████╗ ████║██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
-- ███████║██╔██╗ ██║██║██╔████╔██║███████║   ██║   ██║██║   ██║██╔██╗ ██║
-- ██╔══██║██║╚██╗██║██║██║╚██╔╝██║██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
-- ██║  ██║██║ ╚████║██║██║ ╚═╝ ██║██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
-- ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝

hl.config({ animations = { enabled = true } })

-- Curves (was: bezier = name, x0, y0, x1, y1)
hl.curve("ease",   { type = "bezier", points = { {0.25, 0.1}, {0.25, 1.0} } })
hl.curve("snappy", { type = "bezier", points = { {0.2,  0.9}, {0.25, 1.0} } })

-- Per-leaf animation specs (was: animation = leaf, enabled, speed, bezier, style)
hl.animation({ leaf = "windows",     enabled = true, speed = 3, bezier = "snappy", style = "gnomed" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3, bezier = "snappy", style = "slide bottom" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2, bezier = "snappy", style = "slide" })
hl.animation({ leaf = "layers",      enabled = true, speed = 3, bezier = "snappy", style = "popin" })
hl.animation({ leaf = "fade",        enabled = true, speed = 2, bezier = "snappy" })
hl.animation({ leaf = "border",      enabled = true, speed = 1, bezier = "snappy" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 3, bezier = "snappy", style = "fade" })

-- Drop-down console (Super+grave): "slide top" drops it into view; "slide bottom" retracts it.
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 3, bezier = "snappy", style = "slide top" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 2, bezier = "snappy", style = "slide bottom" })
