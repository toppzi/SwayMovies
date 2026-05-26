#!/usr/bin/env bash
# Open an app on a workspace: launch-on-ws.sh <workspace-number> <command...>
set -euo pipefail
[[ $# -ge 2 ]] || { echo "usage: launch-on-ws.sh <ws> <command...>" >&2; exit 1; }
ws=$1
shift
command -v swaymsg >/dev/null || exec "$@"
swaymsg workspace "number ${ws}" >/dev/null
exec "$@"
