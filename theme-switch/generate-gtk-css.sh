#!/usr/bin/env bash
# Generate gtk.css + gtk-settings.ini from each theme's foot.ini (matches foot/waybar/sway).
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
      v = trim(substr($0, index($0, "=") + 1))
      if (k == key) { print v; exit }
    }
  ' "$foot"
}

write_gtk() {
  local theme_dir="$1"
  local foot="$theme_dir/foot.ini"
  local name
  name=$(basename "$theme_dir")

  [[ -f "$foot" ]] || { echo "skip $name: no foot.ini" >&2; return; }

  local mode accent borders
  mode=$(read_foot "$foot" initial-color-theme main)
  [[ "$mode" == "light" ]] || mode=dark

  local section="colors-$mode"
  local bg fg sel_bg sel_fg
  bg=$(read_foot "$foot" background "$section")
  fg=$(read_foot "$foot" foreground "$section")
  sel_bg=$(read_foot "$foot" selection-background "$section")
  sel_fg=$(read_foot "$foot" selection-foreground "$section")
  accent=$(read_foot "$foot" urls "$section")
  [[ -n "$accent" ]] || accent=$(read_foot "$foot" regular4 "$section")
  borders=$(read_foot "$foot" regular0 "$section")
  [[ -n "$borders" ]] || borders=$(read_foot "$foot" bright0 "$section")

  cat >"$theme_dir/gtk.css" <<EOF
/* GTK / Thunar — ${name} (from foot.ini colors-${mode}) */

@define-color theme_bg_color #${bg};
@define-color theme_fg_color #${fg};
@define-color theme_base_color #${bg};
@define-color theme_text_color #${fg};
@define-color theme_selected_bg_color #${sel_bg};
@define-color theme_selected_fg_color #${sel_fg};
@define-color theme_unfocused_fg_color #${fg};
@define-color insensitive_fg_color #${borders};
@define-color borders #${borders};
@define-color accent_bg_color #${accent};
@define-color accent_color #${accent};
@define-color accent_fg_color #${sel_fg};
@define-color warning_color #${accent};

window,
dialog,
messagedialog {
  background-color: @theme_bg_color;
  color: @theme_fg_color;
}

headerbar,
.titlebar,
toolbar,
actionbar {
  background-color: @theme_bg_color;
  color: @theme_fg_color;
  border-color: @borders;
}

treeview.view,
.view,
textview,
textview text {
  background-color: @theme_base_color;
  color: @theme_text_color;
}

treeview.view:selected,
.view:selected,
row:selected,
*:selected {
  background-color: alpha(@accent_bg_color, 0.35);
  color: @theme_selected_fg_color;
}

treeview.view:selected:focus,
.view:selected:focus,
row:selected:focus {
  background-color: @accent_bg_color;
  color: @accent_fg_color;
}

entry,
combobox button,
spinbutton {
  background-color: @theme_base_color;
  color: @theme_text_color;
  border-color: @borders;
}

button {
  background-color: @theme_selected_bg_color;
  color: @theme_fg_color;
  border-color: @borders;
}

button:hover {
  background-color: shade(@theme_selected_bg_color, 1.08);
}

button:checked,
button:active {
  background-color: @accent_bg_color;
  color: @accent_fg_color;
}

scrollbar slider {
  background-color: @borders;
}

.thunar,
.thunar * {
  color: @theme_fg_color;
}

.thunar gridview,
.thunar treeview,
.thunar .view {
  background-color: @theme_base_color;
  color: @theme_text_color;
}

.thunar .sidebar .view {
  background-color: shade(@theme_bg_color, 1.04);
}

.thunar .standard-view {
  background-color: @theme_base_color;
}

statusbar,
.statusbar,
infobar {
  background-color: @theme_bg_color;
  color: @theme_fg_color;
}
EOF

  local dark=1
  [[ "$mode" == "light" ]] && dark=0

  cat >"$theme_dir/gtk-settings.ini" <<EOF
[Settings]
gtk-application-prefer-dark-theme=${dark}
gtk-theme-name=Adwaita
EOF

  echo "generated gtk for $name ($mode)"
}

main() {
  local d
  for d in "$THEMES_DIR"/*/; do
    [[ -d "$d" ]] || continue
    write_gtk "$d"
  done
}

main "$@"
