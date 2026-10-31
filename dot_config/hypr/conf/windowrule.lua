-- ██╗    ██╗██╗███╗   ██╗██████╗  ██████╗ ██╗    ██╗██████╗ ██╗   ██╗██╗     ███████╗
-- ██║    ██║██║████╗  ██║██╔══██╗██╔═══██╗██║    ██║██╔══██╗██║   ██║██║     ██╔════╝
-- ██║ █╗ ██║██║██╔██╗ ██║██║  ██║██║   ██║██║ █╗ ██║██████╔╝██║   ██║██║     █████╗
-- ██║███╗██║██║██║╚██╗██║██║  ██║██║   ██║██║███╗██║██╔══██╗██║   ██║██║     ██╔══╝
-- ╚███╔███╔╝██║██║ ╚████║██████╔╝╚██████╔╝╚███╔███╔╝██║  ██║╚██████╔╝███████╗███████╗
--  ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝

-- Ignore maximize requests from apps. You'll probably like this.
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Disable blur for floating XWayland window
-- hl.window_rule({ name = "no-blur-xwayland-float", match = { xwayland = true, float = true }, no_blur = true })

-- Rules to handle calendar notifications for betterbird, see https://github.com/hyprwm/Hyprland/issues/4356
hl.window_rule({
    name    = "betterbird-calendar-reminders",
    match   = {
        class         = "^(betterbird)$",
        initial_title = "^(Calendar Reminders)$",
    },
    float   = true,
    size    = "700 400",
    opacity = "0.80 0.70",
})

-- Screensaver (tte in ghostty, launched by hypridle via ~/.local/bin/screensaver-launch)
hl.window_rule({
    name       = "screensaver",
    match      = { class = "^(my\\.screensaver)$" },
    fullscreen = true,
    float      = true,
    animation  = "slide",
})

-- Unity's compile / domain-reload progress window. Every window the editor opens
-- shares one WM class, and this one never sets a title of its own, so it is matched
-- by "untitled + floating" — the main window is tiled and retitles itself to
-- "Unity - <project> - ..." once the project loads, and utility windows (Preferences,
-- Package Manager) carry their own titles, so neither is caught here.
-- Unruled it maps onto whatever workspace you are on and takes the keyboard for the
-- length of the compile, which is loud when the compile was started from a terminal
-- (`unity command recompile`) rather than by you clicking in the editor. Send it to
-- the editor's workspace instead: a real Unity dialog still shows up, next to the
-- editor where you would look for it.
hl.window_rule({
    name  = "unity-progress-window",
    match = {
        class = "^(Unityhub-unity-editor-.*)$",
        title = "^(unityhub-unity-editor-.*)$",
        float = true,
    },
    workspace        = "3 silent",
    no_initial_focus = true,
    suppress_event   = "activatefocus",
})

-- Quick-look viewers: imv for images, zathura for PDFs (see ~/.config/mimeapps.list).
-- These open from nemo, xdg-open and handlr, so they arrive unpredictably mid-task.
-- Tiled, each one re-flows whatever workspace you were working in; floated and centred
-- they behave like a preview popup you glance at and dismiss.
-- NOTE: absolute px, not percentages — `size 60% 75%` parses clean but never applies.
-- NOTE: do NOT `hyprctl reload` to pick these up; on this setup it disconnects every
-- Wayland client (Error 71). Hyprland's own config watcher applies edits on write.
hl.window_rule({
    name   = "quick-look-viewers",
    match  = { class = "^(imv|org\\.pwmt\\.zathura)$" },
    float  = true,
    size   = "1536 1080",
    center = true,
})
