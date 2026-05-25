#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWITCH="$SCRIPT_DIR/theme-switch.sh"

mapfile -t themes < <("$SWITCH" list)
(( ${#themes[@]} > 0 )) || { echo "No themes found." >&2; exit 1; }

current=$("$SWITCH" current)
menu=$(
  for t in "${themes[@]}"; do
    if [[ "$t" == "$current" ]]; then
      printf '%s (active)\n' "$t"
    else
      printf '%s\n' "$t"
    fi
  done
)

choice=$(printf '%s\n' "$menu" | rofi -dmenu -i -p "Theme")
[[ -n "${choice:-}" ]] || exit 0

choice=${choice%% (active)}
exec "$SWITCH" "$choice"
