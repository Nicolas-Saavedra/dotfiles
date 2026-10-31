-- ███╗   ███╗ ██████╗ ███╗   ██╗██╗████████╗ ██████╗ ██████╗ ███████╗
-- ████╗ ████║██╔═══██╗████╗  ██║██║╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
-- ██╔████╔██║██║   ██║██╔██╗ ██║██║   ██║   ██║   ██║██████╔╝███████╗
-- ██║╚██╔╝██║██║   ██║██║╚██╗██║██║   ██║   ██║   ██║██╔══██╗╚════██║
-- ██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██║   ██║   ╚██████╔╝██║  ██║███████║
-- ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝
--
-- External-only when docked: while an external monitor is connected it becomes
-- the sole display at native resolution and the internal panel turns off; when
-- none is present eDP-1 stays on. Screens marked `extend = true` are the
-- exception and sit beside eDP-1 instead.
--
-- Who does what:
--   - This file: the rules, plus the internal panel's state at config load.
--   - scripts/external-monitor-primary.sh: live switching on hotplug. It calls
--     M.apply_external() below (through hyprctl eval) to re-apply these rules.
--   - scripts/lid.sh: lid close/open (bound in conf/misc.lua).
-- Keep `extend = true` here in step with EXTEND_DESCS in that script.
--
-- Run `hyprctl monitors` to read a monitor's description if you swap one in.

local ctx = require("lib.context")

local M = {}

M.internal = "eDP-1"

-- Known externals, matched by description prefix so a rule sticks whichever
-- port the screen negotiates. Every field except `extend` is an hl.monitor field.
M.externals = {
    -- Samsung Odyssey G5 (desk). `auto` flows it right of eDP-1 while both are
    -- on (pinning both to 0x0 was the "monitor overlaps" warning) and resolves
    -- to 0,0 once eDP-1 is off.
    { output = "desc:Samsung Electric Company Odyssey G5",
      mode = "preferred", position = "auto", scale = 1 },

    -- Acer PM161W portable screen (USB-C, shows up as DP-*). Used *with* the
    -- laptop rather than instead of it: eDP-1 stays on and this flows right.
    { output = "desc:Acer Technologies PM161W",
      mode = "preferred", position = "auto", scale = 1, bitdepth = 10,
      extend = true },

    -- Samsung TV (living room, streaming from the browser). Its EDID prefers
    -- 3840x2160@30, which at scale 1 is unreadable from the couch and judders.
    -- 4K60 at scale 2 keeps 1080p-sized UI with sharp text. If the TV shows
    -- "not supported", enable Input Signal Plus for its HDMI port, or fall back
    -- to mode = "1920x1080@60", scale = 1.
    { output = "desc:Samsung Electric Company SAMSUNG 0x01000E00",
      mode = "3840x2160@60", position = "auto", scale = 2 },
}

local INTERNAL_ON  = { output = M.internal, mode = "preferred", position = "0x0", scale = 1 }
local INTERNAL_OFF = { output = M.internal, disabled = true }

-- The rule as hl.monitor takes it (drops our own `extend` marker).
local function spec(rule)
    local s = {}
    for k, v in pairs(rule) do
        if k ~= "extend" then s[k] = v end
    end
    return s
end

-- The M.externals entry whose description prefixes `description`, if any.
local function rule_for(description)
    for _, rule in ipairs(M.externals) do
        local prefix = rule.output:sub(#"desc:" + 1)
        if description:sub(1, #prefix) == prefix then return rule end
    end
end

local function lid_closed()
    local f = io.open("/proc/acpi/button/lid/LID/state", "r")
    if not f then return false end
    local state = f:read("*a")
    f:close()
    return state:find("closed") ~= nil
end

-- What eDP-1 should be right now. Only ever "off" while another screen is
-- confirmed live, so a reload can never leave the session without a display.
local function internal_rule()
    local others, replace = 0, false
    for _, m in ipairs(hl.get_monitors() or {}) do
        if m.name ~= M.internal and m.enabled ~= false then
            others = others + 1
            local rule = rule_for(m.description or "")
            if not (rule and rule.extend) then replace = true end
        end
    end
    if others > 0 and (replace or lid_closed()) then return INTERNAL_OFF end
    return INTERNAL_ON
end

-- Re-apply the rule for the connected output `name` (e.g. "DP-2"), falling back
-- to native mode. Called by scripts/external-monitor-primary.sh as
--   hyprctl eval 'require("conf.monitors").apply_external("DP-2")'
-- because a rule it set later by name would otherwise beat the desc: rule.
function M.apply_external(name)
    local m = hl.get_monitor(name)
    local rule = m and rule_for(m.description or "")
    hl.monitor(rule and spec(rule)
        or { output = name, mode = "preferred", position = "auto", scale = 1 })
end


-- Decided at load, from the current dock and lid state, so a reload while docked
-- leaves the panel alone. (The hyprlang config re-enabled eDP-1 on every reload
-- and then turned it off again, and that bounce could destroy client surfaces.)
hl.monitor(internal_rule())

for _, rule in ipairs(M.externals) do
    hl.monitor(spec(rule))
end

-- At the very first load no output exists yet, so decide again once they do
-- (covers booting docked with the lid shut).
if not ctx.sandbox then
    hl.on("hyprland.start", function() hl.monitor(internal_rule()) end)
end

return M
