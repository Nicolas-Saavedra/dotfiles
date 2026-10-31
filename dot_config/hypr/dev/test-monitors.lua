-- dev/test-monitors.lua — unit test for the monitor policy in conf/monitors.lua.
--
--   lua dev/test-monitors.lua        (from the config root; exits non-zero on failure)
--
-- Loads the module against a stub `hl` and a fake lid, for the dock/lid states
-- a sandbox cannot reproduce: which rule eDP-1 gets at config load, and which
-- rule apply_external() re-applies for a connected screen.

package.path = "./?.lua;" .. package.path

local ACER   = "Acer Technologies PM161W 2632804555V03"
local ODYSSEY = "Samsung Electric Company Odyssey G5 H4ZT900000"

local failures = 0
local function check(name, cond)
    print((cond and "ok   " or "FAIL ") .. name)
    if not cond then failures = failures + 1 end
end

-- Load conf.monitors fresh with the given connected screens and lid state.
-- Returns the module and the specs it passed to hl.monitor, in order.
local function load(screens, lid)
    local applied = {}
    _G.hl = {
        monitor      = function(spec) applied[#applied + 1] = spec end,
        get_monitors = function() return screens end,
        get_monitor  = function(name)
            for _, m in ipairs(screens) do if m.name == name then return m end end
        end,
        on           = function() end,
    }
    local real_open = io.open
    io.open = function(path, ...)
        if path:match("^/proc/acpi/button/lid/") then
            return { read = function() return "state:      " .. lid end, close = function() end }
        end
        return real_open(path, ...)
    end
    package.loaded["conf.monitors"] = nil
    package.loaded["lib.context"] = nil
    local M = require("conf.monitors")
    io.open = real_open
    return M, applied
end

local function internal_of(applied)
    for _, s in ipairs(applied) do if s.output == "eDP-1" then return s end end
end

local edp = { name = "eDP-1", description = "Lenovo Group Limited 0x40A9" }

-- eDP-1 at config load
local _, a = load({}, "open")
check("first load (no outputs yet): eDP-1 on", not internal_of(a).disabled)

_, a = load({ edp }, "closed")
check("lid shut, nothing else connected: eDP-1 stays on", not internal_of(a).disabled)

_, a = load({ edp, { name = "DP-1", description = ODYSSEY } }, "open")
check("Odyssey docked: eDP-1 off", internal_of(a).disabled == true)

_, a = load({ { name = "DP-1", description = ODYSSEY } }, "open")
check("Odyssey docked, eDP-1 already off: stays off (no reload bounce)", internal_of(a).disabled == true)

_, a = load({ edp, { name = "DP-2", description = ACER } }, "open")
local r = internal_of(a)
check("Acer (extend) connected: eDP-1 on at 0x0", not r.disabled and r.position == "0x0")

_, a = load({ edp, { name = "DP-2", description = ACER } }, "closed")
check("Acer connected, lid shut: eDP-1 off", internal_of(a).disabled == true)

_, a = load({ edp, { name = "DP-2", description = ACER }, { name = "HDMI-A-1", description = "Some TV" } }, "open")
check("Acer + unknown screen: external-only wins, eDP-1 off", internal_of(a).disabled == true)

-- Rules handed to hl.monitor never carry the `extend` marker
_, a = load({}, "open")
local clean = true
for _, s in ipairs(a) do if s.extend ~= nil then clean = false end end
check("no `extend` key reaches hl.monitor", clean)

-- apply_external
local M
M, a = load({ edp, { name = "DP-2", description = ACER } }, "open")
local before = #a
M.apply_external("DP-2")
local spec = a[before + 1]
check("apply_external(Acer) re-applies its desc: rule",
      spec.output == "desc:Acer Technologies PM161W" and spec.bitdepth == 10 and spec.extend == nil)

M, a = load({ edp, { name = "HDMI-A-1", description = "Some TV" } }, "open")
before = #a
M.apply_external("HDMI-A-1")
spec = a[before + 1]
check("apply_external(unknown) falls back to native mode by name",
      spec.output == "HDMI-A-1" and spec.mode == "preferred" and spec.position == "auto")

print(failures == 0 and "\nall passed" or ("\n" .. failures .. " failed"))
os.exit(failures == 0 and 0 or 1)
