#!/usr/bin/env bash
# Run from a terminal (kitty: Super+Return) when windows will not close normally.
set -eu

if ! swaymsg -t get_version >/dev/null 2>&1; then
  echo "Cannot reach Sway (swaymsg failed). From a TTY run: loginctl terminate-user $USER"
  exit 1
fi

case "${1:-focused}" in
  focused)
    swaymsg kill
    echo "Sent kill to focused window."
    ;;
  all)
    swaymsg -t get_tree | python3 - <<'PY'
import json, sys

def walk(node):
    if node.get("type") == "con" and node.get("id") is not None:
        name = node.get("app_id") or node.get("window_properties", {}).get("class") or node.get("name")
        if name and name not in ("waybar", "swaybar"):
            print(node["id"])
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        walk(child)

walk(json.load(sys.stdin))
PY
    while read -r cid; do
      swaymsg "[con_id=$cid] kill" >/dev/null
    done
    echo "Closed all non-bar windows."
    ;;
  sway)
    swaymsg exit
    echo "Exiting Sway session."
    ;;
  *)
    echo "Usage: $0 [focused|all|sway]"
    exit 1
    ;;
esac
