#!/usr/bin/env bash
# Sync active SwayMovies wallpaper to SDDM (login window).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
[[ -n "$TARGET_HOME" ]] || TARGET_HOME="$HOME"

THEMES_DIR="${THEMES_DIR:-$TARGET_HOME/.config/theme-switch/themes}"
STATE_FILE="${XDG_STATE_HOME:-$TARGET_HOME/.local/state}/theme-switch/current"

SDDM_THEME="${SDDM_THEME:-03-sway-fedora}"
SDDM_THEME_DIR="/usr/share/sddm/themes/$SDDM_THEME"
SDDM_THEME_USER_CONF="$SDDM_THEME_DIR/theme.conf.user"
SDDM_OVERRIDE_CONF="/etc/sddm.conf.d/99-swaymovies-theme.conf"

die() { echo "sddm-sync: $*" >&2; exit 1; }

expand_home() { sed "s|@HOME@|$TARGET_HOME|g"; }

current_theme() {
  if [[ -f "$STATE_FILE" ]]; then
    tr -d '[:space:]' <"$STATE_FILE"
  else
    echo "terminator"
  fi
}

main() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || die "run as root (example: sudo $0)"
  [[ -d "$SDDM_THEME_DIR" ]] || die "theme directory missing: $SDDM_THEME_DIR"

  local theme_name="${1:-$(current_theme)}"
  local theme_dir="$THEMES_DIR/$theme_name"
  local theme_env="$theme_dir/theme.env"
  [[ -f "$theme_env" ]] || die "missing theme.env: $theme_env"

  # shellcheck disable=SC1090
  source <(expand_home <"$theme_env")
  : "${WALLPAPER:?missing WALLPAPER in $theme_env}"

  local wallpaper="$WALLPAPER"
  [[ -f "$wallpaper" ]] || die "wallpaper not found: $wallpaper"

  install -d -m 0755 "/etc/sddm.conf.d"
  cat >"$SDDM_OVERRIDE_CONF" <<EOF
[Theme]
Current=$SDDM_THEME
EOF

  cat >"$SDDM_THEME_USER_CONF" <<EOF
[General]
background=$wallpaper
EOF

  chmod 0644 "$SDDM_OVERRIDE_CONF" "$SDDM_THEME_USER_CONF"
  echo "Updated SDDM login theme ($SDDM_THEME)"
  echo "Background: $wallpaper"
  echo "Tip: restart SDDM to preview now: sudo systemctl restart sddm"
}

main "$@"
