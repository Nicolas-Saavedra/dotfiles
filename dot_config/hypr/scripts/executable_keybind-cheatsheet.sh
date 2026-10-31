#!/usr/bin/env bash
# Searchable cheatsheet of all Hyprland keybinds (Super+K), rendered in walker's
# dmenu mode. Reads the live binds from `hyprctl binds -j`, so it stays current
# automatically.
#
# Every bind in conf/keybinding.lua carries a plain-language `description`; that
# text is what shows up here, and it is what the search box matches against. A
# bind with no description falls back to its raw dispatcher, which reads badly
# on purpose — it is the cue to go write one.
#
# Rows are laid out as two columns padded to the widest key combo in the file, so
# the descriptions line up. That only looks right in a fixed-width font: walker's
# theme sets one on `.dmenu .item-text` for exactly this reason. --width is set
# wide enough for the longest row (currently 73 chars) because walker ellipsizes
# item text rather than growing the box -- if a description ever shows up cut off
# with a trailing space, that is the number to raise.
set -uo pipefail

# One "MODS, key, action # summary" line per bind, in definition order.
bind_lines() {
  # modmask bits: SHIFT=1, CONTROL=4, ALT=8, SUPER=64. The lid-switch binds
  # (conf/misc.lua) are not keys you press, so they stay out.
  hyprctl binds -j | jq -r '
    def bit($b): ((.modmask / $b) | floor) % 2 == 1;
    .[] | select(.key | startswith("switch:") | not)
    | ([ (if bit(64) then "SUPER" else empty end),
         (if bit(1)  then "SHIFT" else empty end),
         (if bit(4)  then "CONTROL" else empty end),
         (if bit(8)  then "ALT" else empty end) ] | join(" ")) as $mods
    | "\($mods), \(.key), \(.dispatcher) \(.arg)"
      + (if .has_description then " # \(.description)" else "" end)'
}

bind_lines \
  | awk '
      function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }

      # Hyprland spells modifiers inconsistently (SHIFT/Shift/shift, CONTROL/Control).
      # Normalise to one capitalised form so the first column reads uniformly.
      function pretty_mod(m,   u) {
        u = toupper(m)
        if (u == "SUPER" || u == "MOD4")  return "Super"
        if (u == "SHIFT")                 return "Shift"
        if (u == "CONTROL" || u == "CTRL") return "Ctrl"
        if (u == "ALT" || u == "MOD1")    return "Alt"
        return m
      }

      # Turn keysyms and event names into what is printed on the key.
      function pretty_key(k,   u) {
        u = toupper(k)
        if (u == "RETURN" || u == "KP_ENTER") return "Enter"
        if (u == "ESCAPE")     return "Esc"
        if (u == "TAB")        return "Tab"
        if (u == "GRAVE")      return "`"
        if (u == "PERIOD")     return "."
        if (u == "COMMA")      return ","
        if (u == "LEFT")       return "Left"
        if (u == "RIGHT")      return "Right"
        if (u == "UP")         return "Up"
        if (u == "DOWN")       return "Down"
        if (k == "mouse:272")  return "Left Click"
        if (k == "mouse:273")  return "Right Click"
        if (k == "mouse:274")  return "Middle Click"
        if (k == "mouse_down") return "Scroll Down"
        if (k == "mouse_up")   return "Scroll Up"
        if (u == "XF86AUDIORAISEVOLUME")  return "Volume Up"
        if (u == "XF86AUDIOLOWERVOLUME")  return "Volume Down"
        if (u == "XF86AUDIOMUTE")         return "Mute"
        if (u == "XF86AUDIOMICMUTE")      return "Mic Mute"
        if (u == "XF86MONBRIGHTNESSUP")   return "Brightness Up"
        if (u == "XF86MONBRIGHTNESSDOWN") return "Brightness Down"
        if (u == "XF86AUDIONEXT")         return "Next Track"
        if (u == "XF86AUDIOPREV")         return "Prev Track"
        if (u == "XF86AUDIOPLAY")         return "Play"
        if (u == "XF86AUDIOPAUSE")        return "Pause"
        if (length(k) == 1)               return u     # bare letters: q -> Q
        return k
      }

      {
        desc = ""
        if (match($0, /#[[:space:]]*/)) {
          desc = substr($0, RSTART); sub(/^#[[:space:]]*/, "", desc)
          $0 = substr($0, 1, RSTART - 1)
        }

        n = split($0, f, ",")
        mods = trim(f[1]); key = trim(f[2])
        act = ""
        for (i = 3; i <= n; i++) act = act f[i] (i < n ? "," : "")
        act = trim(act); desc = trim(desc)

        # Modifiers arrive space-separated ("SUPER SHIFT CONTROL"); rebuild them
        # as "Super + Shift + Ctrl" so every separator in the combo is identical.
        combo = ""
        nm = split(mods, mlist, /[[:space:]]+/)
        for (i = 1; i <= nm; i++)
          if (mlist[i] != "") combo = combo (combo == "" ? "" : " + ") pretty_mod(mlist[i])

        key = pretty_key(key)
        combo = (combo == "" ? key : combo " + " key)

        combos[NR] = combo
        texts[NR]  = (desc != "" ? desc : act)
        if (length(combo) > width) width = length(combo)
      }

      END {
        # Pad to the widest combo actually present, so a long one such as
        # "Super + Shift + Ctrl + Esc" can never eat into the description column.
        for (i = 1; i <= NR; i++)
          if (combos[i] != "") printf "%-*s  %s\n", width, combos[i], texts[i]
      }
    ' \
  | walker -d -p "Keybinds" --width 820 >/dev/null
