-- Shared facts every module needs: where things live, and whether this
-- instance is a throwaway sandbox (dev/sandbox.sh) rather than the real session.
--
--   local ctx = require("lib.context")
--   hl.exec_cmd(ctx.scripts .. "/lid.sh open")

local home = os.getenv("HOME")

return {
    home     = home,
    hypr_dir = home .. "/.config/hypr",

    -- Helper scripts (see scripts/hypr-ipc.sh for talking to Hyprland from them).
    -- Absolute, so a sandbox run of a copy of this tree still uses the real ones.
    scripts  = home .. "/.config/hypr/scripts",

    -- Set by dev/sandbox.sh for nested test instances. Session-wide side effects
    -- (daemons, systemd/dbus environment, monitor policy) are skipped when true.
    sandbox  = os.getenv("HYPR_SANDBOX") == "1",
}
