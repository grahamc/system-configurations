#!/usr/bin/env bash

# Logic adapted from here:
# https://github.com/artemave/tmux_capture_last_command_output/blob/bd2cca21bc32c2d6652d7b6fdc36cd61409ddd73/plugin.sh

pane_contents=$(tmux capture-pane -e -p -S '-' -J)
# I use this zero-width char to mark the start/end of my prompt. This way I can extract the last command's output
# in here. (see: tmux.fish for how I mark my prompt).
zero_width_char="$(printf '\u200D')"
last_command_output=$(echo "$pane_contents" | tac | sed -e "0,/$zero_width_char/d" | sed -e "0,/$zero_width_char/d" | sed "/$zero_width_char/,\$d" | tac)

if ! choice="$(printf "%s\n" less fzf nvim | fzf --prompt 'command output viewer: ' --no-preview --height ~100% --margin 0,2,0,2 --border rounded)"; then
  exit
fi

case "$choice" in
  less)
    echo "$last_command_output" | LESSCHARSET=utf-8 less -+F
  ;;
  fzf)
    echo "$last_command_output" | fzf --preview-window 35%
  ;;
  nvim)
    echo "$last_command_output" | strip-ansi-escapes | nvim -
  ;;
  *)
    echo 'Error: unknown choice' 1>&2
    exit 1
  ;;
esac
