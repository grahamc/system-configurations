#!/bin/env sh

dbus-monitor --session "type='signal',interface='org.gnome.ScreenSaver'" | \
( while true; do
    read -r X;
    if echo "$X" | grep "boolean false" 1>/dev/null  2>&1; then
      night_switcher_shell_theme="$(dconf read /org/gnome/shell/extensions/nightthemeswitcher/shell-variants/night)"
      dconf write /org/gnome/shell/extensions/user-theme/name "$night_switcher_shell_theme"
      echo "GNOME shell theme changed to '$night_switcher_shell_theme'."
    fi
done )
