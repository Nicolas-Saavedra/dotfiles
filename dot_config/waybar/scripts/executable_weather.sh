#!/usr/bin/env bash
# Waybar module: current conditions and a 3-day outlook from open-meteo.
#
# Ports Omarchy 4's `omarchy.weather` bar widget (MIT). open-meteo needs no API
# key and no account.
#
# Location resolution, in order:
#   1. ~/.config/waybar/weather.conf  ->  LAT=.. LON=.. LABEL=..
#   2. a one-time IP geolocation, cached to that same file
# Step 2 sends your IP to ipapi.co. To avoid that entirely, write the file
# yourself before first run; the lookup is then never attempted.
#
# The emitted `class` matches the #custom-weather.* rules already present in
# style.css, so theming needs no new selectors.
set -uo pipefail

CONF="$HOME/.config/waybar/weather.conf"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-weather.json"
CACHE_TTL=900   # seconds; open-meteo asks for restraint and the data is hourly

fail() { printf '%s\n' '{"text":"","tooltip":"Weather unavailable"}'; exit 0; }

# --- location -----------------------------------------------------------------
if [ -f "$CONF" ]; then . "$CONF"; fi
if [ -z "${LAT:-}" ] || [ -z "${LON:-}" ]; then
  # Providers differ in shape and any one of them can be blocked or rate-limited,
  # so each is tried in turn and normalised to "lat lon city".
  for provider in ipinfo ipapi; do
    case "$provider" in
      ipinfo) geo="$(timeout 8 curl -sf 'https://ipinfo.io/json' 2>/dev/null)" || continue
              read -r LAT LON LABEL <<<"$(printf '%s' "$geo" | jq -r '
                (.loc // "") | split(",") as $l
                | if ($l|length) == 2 then "\($l[0]) \($l[1])" else "" end' 2>/dev/null) $(printf '%s' "$geo" | jq -r '.city // "Here"' 2>/dev/null)" ;;
      ipapi)  geo="$(timeout 8 curl -sf 'http://ip-api.com/json/' 2>/dev/null)" || continue
              read -r LAT LON LABEL <<<"$(printf '%s' "$geo" | jq -r '"\(.lat // "") \(.lon // "") \(.city // "Here")"' 2>/dev/null)" ;;
    esac
    [ -n "${LAT:-}" ] && [ -n "${LON:-}" ] && break
  done
  [ -z "${LAT:-}" ] || [ -z "${LON:-}" ] && fail
  printf 'LAT=%s\nLON=%s\nLABEL=%q\n' "$LAT" "$LON" "${LABEL:-Here}" > "$CONF"
fi
LABEL="${LABEL:-Here}"

# --- fetch (cached) -----------------------------------------------------------
now="$(date +%s)"
mtime=0
[ -f "$CACHE" ] && mtime="$(stat -c %Y "$CACHE" 2>/dev/null || echo 0)"
if [ $((now - mtime)) -ge "$CACHE_TTL" ]; then
  url="https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON"
  url="$url&current=temperature_2m,apparent_temperature,weather_code,is_day"
  url="$url&daily=weather_code,temperature_2m_max,temperature_2m_min&forecast_days=4&timezone=auto"
  if body="$(timeout 8 curl -sf "$url" 2>/dev/null)" && [ -n "$body" ]; then
    printf '%s' "$body" > "$CACHE"
  fi
fi
[ -s "$CACHE" ] || fail

# nf-weather glyphs, verified present in MesloLGS Nerd Font.
glyphs="$(printf '{"clearDay":"\uE30D","clearNight":"\uE32B","cloudyDay":"\uE302","cloudyNight":"\uE37E","fog":"\uE313","rain":"\uE318","snow":"\uE31A","severe":"\uE31D"}')"

jq -c --arg label "$LABEL" --argjson g "$glyphs" '
  def esc: tostring | gsub("&";"&amp;") | gsub("<";"&lt;") | gsub(">";"&gt;");
  # WMO 4677 code groups, collapsed to the icon/class pairs the theme already has.
  def bucket($c):
        if   $c == 0                       then "clear"
        elif $c <= 3                       then "cloudy"
        elif $c == 45 or $c == 48          then "fog"
        elif $c >= 51 and $c <= 67         then "rain"
        elif $c >= 71 and $c <= 77         then "snow"
        elif $c >= 80 and $c <= 82         then "rain"
        elif $c >= 85 and $c <= 86         then "snow"
        elif $c >= 95                      then "severe"
        else "cloudy" end;
  # Glyphs arrive as $g from bash (printf \\uXXXX) rather than being written as
  # literals here: a literal PUA character is silently dropped by any tool in the
  # chain that is not UTF-8 clean, and the module then renders a bare number.
  def glyph($c; $day):
        bucket($c) as $b
        | if   $b == "clear"  then (if $day then $g.clearDay  else $g.clearNight  end)
          elif $b == "cloudy" then (if $day then $g.cloudyDay else $g.cloudyNight end)
          elif $b == "fog"    then $g.fog
          elif $b == "rain"   then $g.rain
          elif $b == "snow"   then $g.snow
          else $g.severe end;
  def cls($c; $day):
        bucket($c) as $b
        | if   $b == "severe" then "severe"
          elif $b == "clear"  then (if $day then "sunnyDay"      else "clearNight"      end)
          elif $b == "rain"   then (if $day then "rainyDay"      else "rainyNight"      end)
          elif $b == "snow"   then (if $day then "snowyIcyDay"   else "snowyIcyNight"   end)
          elif $b == "cloudy" or $b == "fog"
                              then (if $day then "cloudyFoggyDay" else "cloudyFoggyNight" end)
          else "default" end;
  def word($c):
        bucket($c) as $b
        | if $b == "clear" then "Clear" elif $b == "cloudy" then "Cloudy"
          elif $b == "fog" then "Fog"   elif $b == "rain"   then "Rain"
          elif $b == "snow" then "Snow" else "Storm" end;

  .current as $c
  | (($c.is_day // 1) == 1) as $day
  | ($c.weather_code // 0)  as $code
  | ($c.temperature_2m // 0 | round) as $temp
  # Pango letter_spacing on the lone space: one plain space is ~6px, two are
  # ~14px, and the right-hand bar modules sit at ~10px between icon and value.
  | { text:  (glyph($code; $day) + "<span letter_spacing=\"3584\"> </span>" + ($temp|tostring) + "°"),
      class: cls($code; $day),
      alt:   cls($code; $day),
      tooltip:
        ( "<b>" + ($label|esc) + "</b>   " + word($code) + "  " + ($temp|tostring) + "°C"
          + "\nFeels like  " + (($c.apparent_temperature // 0 | round)|tostring) + "°C\n"
          + ( [ range(0; (.daily.time | length)) as $i
                | "\n" + (.daily.time[$i] | esc)
                  + "   " + glyph(.daily.weather_code[$i]; true)
                  + "  " + ((.daily.temperature_2m_min[$i] | round)|tostring) + "°"
                  + " / " + ((.daily.temperature_2m_max[$i] | round)|tostring) + "°"
              ] | join("") ) ) }' < "$CACHE" 2>/dev/null || fail
