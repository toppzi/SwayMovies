# shellcheck shell=bash
# Sourced by wallpaper scripts — do not run directly.
WALLPAPER_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/sway"
WALLPAPER_STATE_FILE="$WALLPAPER_STATE_DIR/last-wallpaper"
THEME_ACTIVE_ENV="${XDG_STATE_HOME:-$HOME/.local/state}/theme-switch/active.env"
WALLPAPER_DEFAULT="${WALLPAPER_DEFAULT:-@HOME@/Pictures/Wallpapers/wallhaven_w89pvq.jpg}"
WALLPAPER_MODE="${WALLPAPER_MODE:-fill}"

if [[ -f "$THEME_ACTIVE_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$THEME_ACTIVE_ENV"
  [[ -n "${WALLPAPER:-}" && -f "$WALLPAPER" ]] && WALLPAPER_DEFAULT="$WALLPAPER"
fi

WALLPAPER_FALLBACK="${WALLPAPER_FALLBACK:-#0c1317}"

esc_sway() { printf '%s' "$1" | sed "s/'/'\\\\''/g"; }

wallpaper_apply() {
  local path="$1" mode="${2:-fill}"
  swaymsg "output * bg '$(esc_sway "$path")' $mode $WALLPAPER_FALLBACK"
}

wallpaper_save_state() {
  local path="$1" mode="${2:-fill}"
  mkdir -p "$WALLPAPER_STATE_DIR"
  printf '%s\n%s\n' "$path" "$mode" >"$WALLPAPER_STATE_FILE"
}

wallpaper_restore_if_possible() {
  local path mode
  if [[ -f "$WALLPAPER_STATE_FILE" ]]; then
    IFS= read -r path <"$WALLPAPER_STATE_FILE" || true
    mode=$(sed -n '2p' "$WALLPAPER_STATE_FILE")
    [[ -z "${mode:-}" ]] && mode="$WALLPAPER_MODE"
    [[ -f "$path" ]] || path="$WALLPAPER_DEFAULT"
  else
    path="$WALLPAPER_DEFAULT"
    mode="$WALLPAPER_MODE"
  fi

  [[ -f "$path" ]] || return 1
  wallpaper_apply "$path" "$mode"
  wallpaper_save_state "$path" "$mode"
  return 0
}
