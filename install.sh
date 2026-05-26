#!/usr/bin/env bash
# Install SwayMovies dotfiles and theme switcher into $HOME.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
expand_home() { sed "s|@HOME@|$HOME|g"; }

echo "Installing SwayMovies from: $REPO_ROOT"

# Theme switcher
install -d "$HOME/.config/theme-switch"
cp -a "$REPO_ROOT/theme-switch/"*.sh "$HOME/.config/theme-switch/"
cp -a "$REPO_ROOT/theme-switch/themes" "$HOME/.config/theme-switch/"
chmod +x "$HOME/.config/theme-switch/"*.sh
if [[ -x "$HOME/.config/theme-switch/generate-kitty-conf.sh" ]]; then
  "$HOME/.config/theme-switch/generate-kitty-conf.sh" || true
fi

# Sway
install -d "$HOME/.config/sway/config.d"
for f in "$REPO_ROOT/config/sway/config.d/"*.conf; do
  expand_home <"$f" >"$HOME/.config/sway/config.d/$(basename "$f")"
done
for f in wallpaper-lib.sh wallpaper-restore.sh restart-sway.sh emergency-close.sh autostart-essentials.sh waybar-restart.sh launch-on-ws.sh; do
  [[ -f "$REPO_ROOT/config/sway/$f" ]] || continue
  expand_home <"$REPO_ROOT/config/sway/$f" >"$HOME/.config/sway/$f"
  chmod +x "$HOME/.config/sway/$f"
done

if [[ ! -f "$HOME/.config/sway/config" ]]; then
  echo "Installing sway config.example → ~/.config/sway/config (edit monitors!)"
  cp "$REPO_ROOT/config/sway/config.example" "$HOME/.config/sway/config"
else
  if grep -q 'set $term foot' "$HOME/.config/sway/config" 2>/dev/null; then
    sed -i 's/set $term foot/set $term kitty/g; s/-terminal foot/-terminal kitty/g' "$HOME/.config/sway/config"
    echo "Updated ~/.config/sway/config: foot → kitty"
  else
    echo "Keeping existing ~/.config/sway/config (see config.example for reference)"
  fi
fi

# Waybar
install -d "$HOME/.config/waybar"
install -m644 "$REPO_ROOT/config/waybar/config.jsonc" "$HOME/.config/waybar/"
[[ -f "$REPO_ROOT/config/waybar/power-menu.sh" ]] && {
  install -m755 "$REPO_ROOT/config/waybar/power-menu.sh" "$HOME/.config/waybar/"
}

# Fastfetch logos (configs are applied per-theme)
install -d "$HOME/fastfetch" "$HOME/.config/fastfetch"
for theme_dir in "$REPO_ROOT/theme-switch/themes"/*/; do
  [[ -f "$theme_dir/fastfetch-logo.txt" ]] || continue
  # shellcheck disable=SC1090
  logo=$(expand_home <"$theme_dir/theme.env" | sed -n 's/^FASTFETCH_LOGO=//p' | tr -d '"')
  [[ -n "$logo" ]] || continue
  install -m644 "$theme_dir/fastfetch-logo.txt" "$HOME/fastfetch/$logo"
  install -m644 "$theme_dir/fastfetch-logo.txt" "$HOME/.config/fastfetch/$logo"
done

# Wallpapers directory
install -d "$HOME/Pictures/Wallpapers"
if [[ -d "$REPO_ROOT/wallpapers/files" ]] && compgen -G "$REPO_ROOT/wallpapers/files/*" >/dev/null; then
  cp -an "$REPO_ROOT/wallpapers/files/"* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true
fi

missing=0
while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  [[ -f "$HOME/Pictures/Wallpapers/$line" ]] && continue
  echo "  missing wallpaper: ~/Pictures/Wallpapers/$line"
  missing=1
done <"$REPO_ROOT/wallpapers/MANIFEST.txt"

if ! command -v xrandr >/dev/null; then
  echo "  missing xrandr (install xorg-x11-server-utils — Lutris will crash without it)"
  missing=1
fi

if (( missing )); then
  echo ""
  echo "Add wallpaper files listed in wallpapers/MANIFEST.txt to ~/Pictures/Wallpapers/"
  echo "Install missing packages above (e.g. sudo dnf install xorg-x11-server-utils)"
fi

# Apply default theme
if [[ -x "$HOME/.config/theme-switch/theme-switch.sh" ]]; then
  if [[ -f "$HOME/.local/state/theme-switch/current" ]]; then
    "$HOME/.config/theme-switch/theme-switch.sh" "$("$HOME/.config/theme-switch/theme-switch.sh" current)" || true
  else
    "$HOME/.config/theme-switch/theme-switch.sh" terminator || true
  fi
fi

cat <<EOF

Done.

  Theme menu:  Super+Shift+T
  CLI:       ~/.config/theme-switch/theme-switch.sh list
             ~/.config/theme-switch/theme-switch.sh <theme>

  Edit ~/.config/sway/config for your monitor layout before swaymsg reload.
EOF
