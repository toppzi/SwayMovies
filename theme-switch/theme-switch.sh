#!/usr/bin/env bash
# Apply a desktop theme (sway, waybar, foot, rofi, wallpaper, fastfetch).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="${THEMES_DIR:-$SCRIPT_DIR/themes}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/theme-switch"
STATE_FILE="$STATE_DIR/current"
ACTIVE_ENV="$STATE_DIR/active.env"

die() { echo "theme-switch: $*" >&2; exit 1; }

expand_home() { sed "s|@HOME@|$HOME|g"; }

list_themes() {
  local d name
  for d in "$THEMES_DIR"/*/; do
    [[ -d "$d" ]] || continue
    name=$(basename "$d")
    [[ -f "$d/theme.env" ]] || continue
    printf '%s\n' "$name"
  done | sort
}

current_theme() {
  if [[ -f "$STATE_FILE" ]]; then
    cat "$STATE_FILE"
  else
    echo "terminator"
  fi
}

install_file() {
  local src="$1" dest="$2"
  install -D -m 0644 "$src" "$dest"
}

install_expanded() {
  local src="$1" dest="$2"
  expand_home <"$src" | install -D -m 0644 /dev/stdin "$dest"
}

apply_theme() {
  local name="$1"
  local dir="$THEMES_DIR/$name"

  [[ -d "$dir" ]] || die "unknown theme '$name' (themes: $(list_themes | tr '\n' ' '))"
  [[ -f "$dir/theme.env" ]] || die "missing theme.env in $dir"

  # shellcheck disable=SC1090
  if ! source <(expand_home <"$dir/theme.env"); then
    die "failed to load $dir/theme.env (quote values with spaces)"
  fi
  : "${WALLPAPER:?missing WALLPAPER in theme.env}"
  : "${WALLPAPER_FALLBACK:?missing WALLPAPER_FALLBACK in theme.env}"
  : "${FASTFETCH_LOGO:?missing FASTFETCH_LOGO in theme.env}"

  install_file "$dir/sway-theme.conf" "$HOME/.config/sway/config.d/40-theme.conf"
  install_expanded "$dir/sway-display.conf" "$HOME/.config/sway/config.d/05-display.conf"
  install_file "$dir/waybar.css" "$HOME/.config/waybar/style.css"
  install_file "$dir/foot.ini" "$HOME/.config/foot/foot.ini"
  install_file "$dir/rofi.rasi" "$HOME/.config/rofi/config.rasi"

  install_file "$dir/fastfetch.jsonc" "$HOME/fastfetch/config.jsonc"
  install_file "$dir/fastfetch.jsonc" "$HOME/.config/fastfetch/config.jsonc"
  install_file "$dir/fastfetch-logo.txt" "$HOME/fastfetch/$(basename "$FASTFETCH_LOGO")"
  install_file "$dir/fastfetch-logo.txt" "$HOME/.config/fastfetch/$(basename "$FASTFETCH_LOGO")"

  mkdir -p "$STATE_DIR"
  printf '%s\n' "$name" >"$STATE_FILE"
  expand_home <"$dir/theme.env" >"$ACTIVE_ENV"

  if command -v swaymsg >/dev/null 2>&1 && swaymsg -t get_version >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    source "$HOME/.config/sway/wallpaper-lib.sh"
    wallpaper_apply "$WALLPAPER" "${WALLPAPER_MODE:-fill}" || true
    wallpaper_save_state "$WALLPAPER" "${WALLPAPER_MODE:-fill}"
    swaymsg reload || true
    pkill -x waybar 2>/dev/null || true
    waybar &
  else
    echo "Note: Sway not running — configs saved; reload Sway or run: swaymsg reload"
  fi

  notify-send -a theme-switch "Theme: ${THEME_LABEL:-$name}" "Wallpaper and colors updated." 2>/dev/null || true
  echo "Applied theme: ${THEME_LABEL:-$name}"
}

usage() {
  cat <<EOF
Usage: theme-switch.sh <theme-name>
       theme-switch.sh list
       theme-switch.sh current
       theme-switch.sh menu

Themes live in: $THEMES_DIR
EOF
}

main() {
  case "${1:-menu}" in
    -h|--help) usage ;;
    list) list_themes ;;
    current) current_theme ;;
    menu) exec "$SCRIPT_DIR/theme-menu.sh" ;;
    "") exec "$SCRIPT_DIR/theme-menu.sh" ;;
    *) apply_theme "$1" ;;
  esac
}

main "$@"
