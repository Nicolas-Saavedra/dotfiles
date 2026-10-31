-- ███████╗ ██████╗██████╗  █████╗ ████████╗ ██████╗██╗  ██╗██████╗  █████╗ ██████╗
-- ██╔════╝██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██║  ██║██╔══██╗██╔══██╗██╔══██╗
-- ███████╗██║     ██████╔╝███████║   ██║   ██║     ███████║██████╔╝███████║██║  ██║
-- ╚════██║██║     ██╔══██╗██╔══██║   ██║   ██║     ██╔══██║██╔═══╝ ██╔══██║██║  ██║
-- ███████║╚██████╗██║  ██║██║  ██║   ██║   ╚██████╗██║  ██║██║     ██║  ██║██████╔╝
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═════╝
--
-- Drop-down console: special:scratchpad presented as a Quake console that drops
-- over the current workspace. Ported from Omarchy's default/hypr/qconsole.lua.
-- The bottom gap is recomputed on monitor.layout_changed / monitor.focused, so
-- the bind can toggle the special workspace directly.
-- Bindings are in conf/keybinding.lua (Super+grave / Super+Shift+grave); the
-- dimming and retract-on-switch options in conf/appearance.lua / conf/misc.lua,
-- and the slide animations in conf/animation.lua.

local share = 0.5 -- fraction of the work area the console covers, from the top

-- Seeded on first open (and again after its last window closes), not at boot.
-- The [workspace ...] prefix pins the spawn to the console rather than trusting
-- initial_workspace_tracking.
local seed = "[workspace special:scratchpad silent] ghostty --class=scratchpad.herdr -e herdr --session scratch"

-- Only rewrite the rule when the number actually moves: monitor.focused fires
-- on every hop between screens and a rewrite costs a state refresh.
local covering = nil

local function cover(bottom)
    if covering == bottom then return end
    covering = bottom
    hl.workspace_rule({
        workspace        = "special:scratchpad",
        gaps_in          = 0,
        gaps_out         = { top = 0, right = 0, bottom = bottom, left = 0 },
        no_border        = true,
        on_created_empty = seed,
    })
end

-- Monitor dimensions are physical pixels; gaps and reserved areas are logical.
-- monitor.focused passes the newly focused monitor; use it, because inside that
-- handler hl.get_active_monitor() still returns the one focus just left.
local function fit(focused)
    local monitor = focused or hl.get_active_monitor()
    if not monitor or not monitor.scale or monitor.scale <= 0 then return end
    local reserved = monitor.reserved
    local usable = monitor.height / monitor.scale - reserved.top - reserved.bottom
    cover(math.max(0, math.floor(usable * (1 - share))))
end

cover(0) -- never leave the console unruled before a monitor can be read
fit()
hl.on("monitor.layout_changed", function() fit() end)
hl.on("monitor.focused", fit)
