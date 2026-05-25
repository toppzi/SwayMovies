#!/usr/bin/env bash
# Re-apply wallpaper on every sway reload/login.
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/wallpaper-lib.sh"

wallpaper_restore_if_possible
