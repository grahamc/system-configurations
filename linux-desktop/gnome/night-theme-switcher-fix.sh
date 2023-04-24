#!/usr/bin/env sh

dbus-monitor --session "type='signal',interface='org.gnome.ScreenSaver'" | \
( while true; do
    read -r X;
    if echo "$X" | grep "boolean false" 1>/dev/null  2>&1; then
      gtk_theme="$(dconf read /org/gnome/desktop/interface/gtk-theme)"
      dconf write /org/gnome/shell/extensions/user-theme/name "$gtk_theme"
      echo "GNOME shell theme changed to '$gtk_theme'."
    fi
done )
