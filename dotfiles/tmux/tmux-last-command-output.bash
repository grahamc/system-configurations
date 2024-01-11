#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Logic adapted from here:
# https://github.com/artemave/tmux_capture_last_command_output/blob/bd2cca21bc32c2d6652d7b6fdc36cd61409ddd73/plugin.sh

if [ -z "${TMUX:-}" ]; then
  exit
fi

pane_contents=$(tmux capture-pane -e -p -S '-' -J)
# \u00A0 is a non-breaking space. I use it to determine where my prompt starts and ends so I can view the
# output of the last command. (see: tmux.fish for how it gets added to my prompt).
prompt_pattern="$(printf '\u00A0')"
last_command_output=$(echo "$pane_contents" | tac | sed -e "0,/$prompt_pattern/d" | sed -e "0,/$prompt_pattern/d" | sed "/$prompt_pattern/,\$d" | tac)

if ! choice="$(printf "%s\n" fzf nvim | fzf --prompt 'command output viewer: ' --no-preview --height ~100% --margin 0,2,0,2 --border rounded)"; then
  exit
fi

case "$choice" in
fzf)
  echo "$last_command_output" | fzf --preview-window 35%
  ;;
nvim)
  echo "$last_command_output" | page
  ;;
*)
  echo 'Error: unknown choice' 1>&2
  exit 1
  ;;
esac
