-- ██╗  ██╗███████╗██╗   ██╗██████╗ ██╗███╗   ██╗██████╗ ██╗███╗   ██╗ ██████╗
-- ██║ ██╔╝██╔════╝╚██╗ ██╔╝██╔══██╗██║████╗  ██║██╔══██╗██║████╗  ██║██╔════╝
-- █████╔╝ █████╗   ╚████╔╝ ██████╔╝██║██╔██╗ ██║██║  ██║██║██╔██╗ ██║██║  ███╗
-- ██╔═██╗ ██╔══╝    ╚██╔╝  ██╔══██╗██║██║╚██╗██║██║  ██║██║██║╚██╗██║██║   ██║
-- ██║  ██╗███████╗   ██║   ██████╔╝██║██║ ╚████║██████╔╝██║██║ ╚████║╚██████╔╝
-- ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═════╝ ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝
--
-- Every bind carries a plain-language description; scripts/keybind-cheatsheet.sh
-- (Super+K) reads them back from `hyprctl binds -j`, so a bind without one shows
-- up there as its raw dispatcher — the cue to go write one.
--
-- Flag mapping from hyprlang: bindl = { locked }, bindel = { locked, repeating },
-- bindm = { mouse } (read by 0.57+; 0.56 ignores it and the drag/resize
-- dispatchers end the drag on button release by themselves).
-- The lid switch binds live in conf/misc.lua.

local ctx      = require("lib.context")
local programs = require("conf.programs")

local s       = ctx.scripts
local mainMod = "SUPER"

-- hl.bind with the description as a required positional argument.
local function bind(keys, dispatcher, desc, opts)
    opts = opts or {}
    opts.description = desc
    return hl.bind(keys, dispatcher, opts)
end

local function sh(cmd) return hl.dsp.exec_cmd(cmd) end

-- SIGTERM the focused window's process, for apps that ignore a close request.
local function kill_active()
    local w = hl.get_active_window()
    if w and w.pid and w.pid > 0 then hl.exec_cmd("kill " .. w.pid) end
end


-- Apps / session
bind(mainMod .. " + Return",                   sh(programs.terminal),                               "Open a terminal")
bind(mainMod .. " + SHIFT + Return",           sh("ghostty -e herdr"),                              "Open a terminal running herdr")
bind(mainMod .. " + Q",                        hl.dsp.window.close(),                               "Close the focused window")
bind(mainMod .. " + SHIFT + Q",                kill_active,                                         "Force-kill the focused window")
bind(mainMod .. " + SHIFT + CONTROL + Escape", hl.dsp.exit(),                                       "Exit Hyprland and log out")
bind(mainMod .. " + E",                        sh(programs.file_manager),                           "Open the file manager")
bind(mainMod .. " + S",                        sh(programs.file_manager .. " " .. ctx.home .. "/Programming/online_profile/System"), "Open the System folder in the file manager")
bind(mainMod .. " + B",                        sh(s .. "/wallpaper-menu.sh"),                       "Wallpaper rotation menu")
bind(mainMod .. " + SHIFT + B",                sh(s .. "/wallpaper-set.sh"),                        "Set a specific wallpaper now")
bind(mainMod .. " + F",                        hl.dsp.window.float({ action = "toggle" }),          "Toggle floating for the focused window")
bind(mainMod .. " + W",                        sh("walker"),                                        "Open the app launcher")
bind(mainMod .. " + L",                        sh("hyprlock"),                                      "Lock the screen")
bind(mainMod .. " + SHIFT + L",                sh(ctx.home .. "/.local/bin/screensaver-launch"),    "Start the screensaver")
bind(mainMod .. " + P",                        sh(s .. "/open-ticket.sh"),                          "Open a Linear ticket (ENG-123) or GitHub PR (123)")
bind(mainMod .. " + J",                        hl.dsp.layout("togglesplit"),                        "Toggle split direction (dwindle layout)")
bind(mainMod .. " + SHIFT + S",                sh("hyprshot -m region -o " .. ctx.home .. "/Pictures/Screenshots"), "Screenshot a region to a file")
bind(mainMod .. " + SHIFT + A",                sh(s .. "/annotate.sh"),                             "Screenshot a region and annotate it")
bind(mainMod .. " + CONTROL + S",              sh(s .. "/ocr.sh"),                                  "Copy text from a screen region (OCR)")
bind(mainMod .. " + C",                        sh(s .. "/colorpicker.sh"),                          "Pick a screen color and copy it as hex")
bind(mainMod .. " + SHIFT + C",                sh(s .. "/colorpicker.sh rgb"),                      "Pick a screen color and copy it as rgb()")
bind(mainMod .. " + SHIFT + R",                sh(s .. "/record-toggle.sh"),                        "Start or stop a screen recording")
bind(mainMod .. " + SHIFT + P",                sh(ctx.home .. "/.config/waybar/scripts/pomodoro.sh --toggle"), "Start, pause or resume the pomodoro timer")
bind(mainMod .. " + K",                        sh(s .. "/keybind-cheatsheet.sh"),                   "Show this keybind cheatsheet")
bind(mainMod .. " + PERIOD",                   sh("walker -m symbols"),                             "Pick an emoji or symbol")
bind(mainMod .. " + V",                        sh("walker -m clipboard"),                           "Browse clipboard history")

-- Drop-down console (Omarchy-style Quake scratchpad). conf/scratchpad.lua keeps
-- the workspace rule sized to the focused monitor, so the bind just toggles it.
bind(mainMod .. " + grave",         hl.dsp.workspace.toggle_special("scratchpad"),                           "Toggle the drop-down herdr console")
bind(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }), "Move the focused window to the drop-down console")

-- Emergency escape hatch: force the internal laptop panel back on. Blind-typeable
-- if the external-monitor handler ever leaves you with a black screen while docked.
-- Uses force-internal.sh (escalating recovery) because a plain monitor rule
-- silently fails to re-enable eDP-1 from a zero-monitor state on aquamarine.
bind(mainMod .. " + SHIFT + M", sh(s .. "/force-internal.sh"), "Force the internal laptop display back on")

-- Multi-monitor (laptop + extended screen, e.g. the Acer portable). +1 cycles,
-- so with two screens it just flips between them.
bind(mainMod .. " + TAB",           hl.dsp.focus({ monitor = "+1" }),          "Jump to the other monitor's workspace")
bind(mainMod .. " + SHIFT + TAB",   hl.dsp.window.move({ monitor = "+1" }),    "Move the focused window to the other monitor")
bind(mainMod .. " + CONTROL + TAB", hl.dsp.workspace.move({ monitor = "+1" }), "Move the current workspace to the other monitor")

bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Toggle fullscreen for the focused window")


-- Move focus with mainMod + arrow keys
bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left"  }), "Move focus to the window on the left")
bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), "Move focus to the window on the right")
bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up"    }), "Move focus to the window above")
bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down"  }), "Move focus to the window below")

-- Switch workspaces with mainMod + [0-9]; move the active window with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- workspace 10 is on key 0
    bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }),       "Switch to workspace " .. i)
    bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), "Move the focused window to workspace " .. i)
end

-- Scroll through existing workspaces with mainMod + scroll
bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Switch to the next workspace")
bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), "Switch to the previous workspace")

-- Move/resize windows with mainMod + LMB/RMB and dragging
bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   "Drag to move a window",   { mouse = true })
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), "Drag to resize a window", { mouse = true })


-- Laptop multimedia keys for volume and LCD brightness, with swayosd overlay.
-- Brightness goes through brightness.sh: backlight on eDP-1, DDC/CI on externals.
local held = function() return { locked = true, repeating = true } end
bind("XF86AudioRaiseVolume",  sh("swayosd-client --output-volume raise"),       "Raise the output volume",       held())
bind("XF86AudioLowerVolume",  sh("swayosd-client --output-volume lower"),       "Lower the output volume",       held())
bind("XF86AudioMute",         sh("swayosd-client --output-volume mute-toggle"), "Mute or unmute the output",     held())
bind("XF86AudioMicMute",      sh("swayosd-client --input-volume mute-toggle"),  "Mute or unmute the microphone", held())
bind("XF86MonBrightnessUp",   sh(s .. "/brightness.sh up"),                     "Increase screen brightness",    held())
bind("XF86MonBrightnessDown", sh(s .. "/brightness.sh down"),                   "Decrease screen brightness",    held())

-- Requires playerctl
bind("XF86AudioNext",  sh("playerctl next"),       "Skip to the next track",     { locked = true })
bind("XF86AudioPause", sh("playerctl play-pause"), "Play or pause media",        { locked = true })
bind("XF86AudioPlay",  sh("playerctl play-pause"), "Play or pause media",        { locked = true })
bind("XF86AudioPrev",  sh("playerctl previous"),   "Skip to the previous track", { locked = true })
