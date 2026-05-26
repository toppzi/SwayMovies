#!/usr/bin/env bash
# Apply a desktop theme (sway, waybar, kitty, rofi, gtk/thunar, wallpaper, fastfetch).
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
    tr -d '[:space:]' <"$STATE_FILE"
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
  local on_login="${2:-false}"
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
  if [[ -f "$dir/kitty.conf" ]]; then
    install_file "$dir/kitty.conf" "$HOME/.config/kitty/kitty.conf"
  elif [[ -f "$dir/foot.ini" && -x "$SCRIPT_DIR/generate-kitty-conf.sh" ]]; then
    THEMES_DIR="$(dirname "$dir")" "$SCRIPT_DIR/generate-kitty-conf.sh" "$name"
    install_file "$dir/kitty.conf" "$HOME/.config/kitty/kitty.conf"
  fi
  install_file "$dir/rofi.rasi" "$HOME/.config/rofi/config.rasi"

  if [[ -f "$dir/gtk.css" ]]; then
    install_file "$dir/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"
    install_file "$dir/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
  fi
  if [[ -f "$dir/gtk-settings.ini" ]]; then
    install_file "$dir/gtk-settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
    install_file "$dir/gtk-settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
    local gtk_dark=1
    grep -q 'gtk-application-prefer-dark-theme=0' "$dir/gtk-settings.ini" && gtk_dark=0
    if command -v gsettings >/dev/null; then
      if [[ "$gtk_dark" -eq 1 ]]; then
        gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
      else
        gsettings set org.gnome.desktop.interface color-scheme prefer-light 2>/dev/null || true
        gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3 2>/dev/null || true
      fi
    fi
  fi

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
    # Waybar is restarted once by exec_always → waybar-restart.sh (do not start it here)
    if [[ "$on_login" != true ]] && pgrep -x thunar >/dev/null; then
      timeout 2 thunar --quit 2>/dev/null || pkill -x thunar 2>/dev/null || true
      (sleep 0.2; thunar) >/dev/null 2>&1 &
    fi
    if [[ "$on_login" != true ]] && command -v kitty >/dev/null; then
      if kitty @ ls >/dev/null 2>&1; then
        kitty @ set-colors --all "$HOME/.config/kitty/kitty.conf" 2>/dev/null || true
      fi
    fi
  else
    echo "Note: Sway not running — configs saved; reload Sway or run: swaymsg reload"
  fi

  if [[ "$on_login" != true ]]; then
    notify-send -a theme-switch "Theme: ${THEME_LABEL:-$name}" "Wallpaper and colors updated." 2>/dev/null || true
  fi
  if [[ "$on_login" == true ]]; then
    echo "Login theme: ${THEME_LABEL:-$name}"
  else
    echo "Applied theme: ${THEME_LABEL:-$name}"
    if [[ -d "/usr/share/sddm/themes/03-sway-fedora" ]]; then
      echo "Sync SDDM login background: sudo $HOME/.config/theme-switch/sddm-sync.sh $name"
    fi
  fi
}

usage() {
  cat <<EOF
Usage: theme-switch.sh <theme-name>
       theme-switch.sh list
       theme-switch.sh current
       theme-switch.sh menu
       theme-switch.sh login

Themes live in: $THEMES_DIR
EOF
}

main() {
  case "${1:-menu}" in
    -h|--help) usage ;;
    list) list_themes ;;
    current) current_theme ;;
    login) apply_theme "$(current_theme)" true ;;
    menu) exec "$SCRIPT_DIR/theme-menu.sh" ;;
    "") exec "$SCRIPT_DIR/theme-menu.sh" ;;
    *) apply_theme "$1" ;;
  esac
}

main "$@"
