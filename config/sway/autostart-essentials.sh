#!/usr/bin/env bash
# Sway session essentials (polkit, NetworkManager, XDG portals).
set -euo pipefail

# Help GTK/Qt apps and user systemd units see the Wayland session.
if [[ -f "$HOME/.config/gtk-3.0/settings.ini" ]]; then
  GTK_THEME=$(grep -m1 '^gtk-theme-name=' "$HOME/.config/gtk-3.0/settings.ini" | cut -d= -f2-)
  export GTK_THEME
fi

if command -v dbus-update-activation-environment >/dev/null; then
  dbus-update-activation-environment --systemd \
    WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK DISPLAY XDG_SESSION_TYPE GTK_THEME
fi
if command -v systemctl >/dev/null; then
  systemctl --user import-environment \
    WAYLAND_DISPLAY XDG_CURRENT_DESKTOP SWAYSOCK DISPLAY XDG_SESSION_TYPE 2>/dev/null || true
  systemctl --user start \
    xdg-desktop-portal.service \
    xdg-desktop-portal-gtk.service \
    xdg-desktop-portal-wlr.service 2>/dev/null || true
fi

# Privilege prompts (Fedora 41+: mate-polkit replaces polkit-gnome)
for agent in \
  /usr/libexec/polkit-mate-authentication-agent-1 \
  /usr/libexec/polkit-gnome-authentication-agent-1 \
  /usr/libexec/polkit-kde-authentication-agent-1 \
  /usr/libexec/xfce-polkit \
  /usr/libexec/lxqt-policykit-agent; do
  if [[ -x "$agent" ]]; then
    "$agent" &
    break
  fi
done

# NetworkManager tray icon
if command -v nm-applet >/dev/null; then
  nm-applet &
fi
