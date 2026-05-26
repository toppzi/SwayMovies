#!/usr/bin/env bash
# Generate kitty.conf from each theme's foot.ini (shared palette with gtk/waybar).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="${THEMES_DIR:-$SCRIPT_DIR/themes}"

read_foot() {
  local foot="$1" key="$2" section="${3:-}"
  awk -v section="$section" -v key="$key" '
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    $0 ~ /^\[/ {
      in_section = (section == "" || trim(substr($0, 2, length($0) - 2)) == section)
      next
    }
    in_section && $0 ~ /^[[:space:]]*[^#=]+=/ {
      split($0, a, "=")
      k = trim(a[1])
      if (k == key) { print trim(substr($0, index($0, "=") + 1)); exit }
    }
  ' "$foot"
}

write_kitty() {
  local theme_dir="$1"
  local foot="$theme_dir/foot.ini"
  local name
  name=$(basename "$theme_dir")

  [[ -f "$foot" ]] || { echo "skip $name: no foot.ini" >&2; return; }

  local mode alpha
  mode=$(read_foot "$foot" initial-color-theme main)
  [[ "$mode" == "light" ]] || mode=dark

  local section="colors-$mode"
  local bg fg sel_bg sel_fg urls alpha_val
  local r0 r1 r2 r3 r4 r5 r6 r7 b0 b1 b2 b3 b4 b5 b6 b7

  bg=$(read_foot "$foot" background "$section")
  fg=$(read_foot "$foot" foreground "$section")
  sel_bg=$(read_foot "$foot" selection-background "$section")
  sel_fg=$(read_foot "$foot" selection-foreground "$section")
  urls=$(read_foot "$foot" urls "$section")
  alpha_val=$(read_foot "$foot" alpha "$section")
  [[ -n "$alpha_val" ]] || alpha_val=$(read_foot "$foot" alpha main)
  [[ -n "$alpha_val" ]] || alpha_val=1.0

  r0=$(read_foot "$foot" regular0 "$section")
  r1=$(read_foot "$foot" regular1 "$section")
  r2=$(read_foot "$foot" regular2 "$section")
  r3=$(read_foot "$foot" regular3 "$section")
  r4=$(read_foot "$foot" regular4 "$section")
  r5=$(read_foot "$foot" regular5 "$section")
  r6=$(read_foot "$foot" regular6 "$section")
  r7=$(read_foot "$foot" regular7 "$section")
  b0=$(read_foot "$foot" bright0 "$section")
  b1=$(read_foot "$foot" bright1 "$section")
  b2=$(read_foot "$foot" bright2 "$section")
  b3=$(read_foot "$foot" bright3 "$section")
  b4=$(read_foot "$foot" bright4 "$section")
  b5=$(read_foot "$foot" bright5 "$section")
  b6=$(read_foot "$foot" bright6 "$section")
  b7=$(read_foot "$foot" bright7 "$section")

  cat >"$theme_dir/kitty.conf" <<EOF
# Kitty — ${name} (from foot.ini colors-${mode})

# Theme colors
foreground            #${fg}
background            #${bg}
selection_foreground  #${sel_fg}
selection_background  #${sel_bg}
cursor                #${fg}
cursor_text_color     #${bg}
url_color             #${urls}

color0  #${r0}
color1  #${r1}
color2  #${r2}
color3  #${r3}
color4  #${r4}
color5  #${r5}
color6  #${r6}
color7  #${r7}
color8  #${b0}
color9  #${b1}
color10 #${b2}
color11 #${b3}
color12 #${b4}
color13 #${b5}
color14 #${b6}
color15 #${b7}

background_opacity ${alpha_val}

# Terminal behavior (shared across themes)
font_family      Noto Sans Mono
font_size        11.0
bold_font        auto
italic_font      auto
bold_italic_font auto

enable_wayland yes
wayland_titlebar_color background

scrollback_lines 10000
wheel_scroll_multiplier 3.0
touch_scroll_multiplier 1.0

cursor_shape block
cursor_blink_interval 0

window_padding_width 8
placement_strategy center
confirm_os_window_close 0

allow_remote_control yes
listen_on unix:@kitty-swaymovies

shell .
shell_integration enabled

map ctrl+shift+equal  change_font_size all +1.0
map ctrl+shift+minus  change_font_size all -1.0
map ctrl+shift+0      change_font_size all 0
EOF

  echo "generated kitty for $name ($mode)"
}

main() {
  local d
  if [[ $# -gt 0 ]]; then
    for d in "$@"; do
      write_kitty "$THEMES_DIR/$d"
    done
    return
  fi
  for d in "$THEMES_DIR"/*/; do
    [[ -d "$d" ]] || continue
    write_kitty "$d"
  done
}

main "$@"
