#!/usr/bin/env sh

fix_theme() {
  gtk_theme="$(dconf read /org/gnome/desktop/interface/gtk-theme)"
  shell_theme='Fluent-round-Dark'
  if echo "$gtk_theme" | grep -q Light; then
    shell_theme='Fluent-round'
  fi
  dconf write /org/gnome/shell/extensions/user-theme/name "'$shell_theme'"
  echo "GNOME shell theme changed to '$shell_theme'."
}

# so it fixes the theme as soon as I login
fix_theme

dbus-monitor --session "type='signal',interface='org.gnome.ScreenSaver'" | \
( while true; do
    read -r X;
    if echo "$X" | grep "boolean false" 1>/dev/null  2>&1; then
      fix_theme
    fi
done )
