#!/bin/sh
# Run from a TTY (Ctrl+Alt+F3) if Sway is stuck.
set -eu

user="${1:-${USER:-$(id -un)}}"
echo "Stopping Sway session for $user..."

# Prefer a clean session stop; fall back to killing the compositor.
if loginctl list-sessions --no-legend 2>/dev/null | awk -v u="$user" '$3==u {print $1}' | while read -r sid; do
  loginctl terminate-session "$sid" 2>/dev/null || true
done; then
  :
fi

pkill -u "$user" -x sway 2>/dev/null || true
pkill -u "$user" -x swaybg 2>/dev/null || true
pkill -u "$user" -x waybar 2>/dev/null || true

echo "Done. Switch to the login screen (Ctrl+Alt+F2) and sign in again."
