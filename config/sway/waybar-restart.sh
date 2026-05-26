#!/usr/bin/env bash
# Single Waybar instance (safe for sway reload and exec_always).
pkill -x waybar 2>/dev/null || true
sleep 0.05
exec waybar
