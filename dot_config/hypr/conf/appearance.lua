--  █████╗ ██████╗ ██████╗ ███████╗ █████╗ ██████╗  █████╗ ███╗   ██╗ ██████╗███████╗
-- ██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔════╝
-- ███████║██████╔╝██████╔╝█████╗  ███████║██████╔╝███████║██╔██╗ ██║██║     █████╗
-- ██╔══██║██╔═══╝ ██╔═══╝ ██╔══╝  ██╔══██║██╔══██╗██╔══██║██║╚██╗██║██║     ██╔══╝
-- ██║  ██║██║     ██║     ███████╗██║  ██║██║  ██║██║  ██║██║ ╚████║╚██████╗███████╗
-- ╚═╝  ╚═╝╚═╝     ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝

hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 12,

        border_size = 2,

        col = {
            active_border   = "rgba(cdd6f4aa)",
            inactive_border = "rgba(595959aa)",
        },

        resize_on_border = true,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 2,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        dim_special = 0.6, -- Dim the workspace under the drop-down console (Super+grave)

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a, -- was rgba(1a1a1aee) — alpha leads in 0xAARRGGBB
        },

        blur = {
            enabled           = true,
            size              = 6,
            passes            = 3,
            new_optimizations = true,
            ignore_opacity    = true,
        },
    },
})

-- Blur waybar
-- hl.layer_rule({ name = "blur-waybar", match = { namespace = "waybar" }, blur = true })

-- Blur wlogout
hl.layer_rule({
    name  = "blur-wlogout",
    match = { namespace = "logout_dialog" },
    blur  = true,
})

-- Blur swaync
hl.layer_rule({
    name         = "blur-swaync-cc",
    match        = { namespace = "swaync-control-center" },
    blur         = true,
    ignore_alpha = 0.5,
})

hl.layer_rule({
    name         = "blur-swaync-notify",
    match        = { namespace = "swaync-notification-window" },
    blur         = true,
    ignore_alpha = 0.5,
})

-- Slurp region selector: no fade animation, else its white tint bleeds into screenshots
hl.layer_rule({
    name    = "no-anim-slurp",
    match   = { namespace = "selection" },
    no_anim = true,
})
