#!/bin/sh

# Move the commandline cursor to where the mouse was clicked. It works by repeatedly sending left/right arrow keypresses
# until either the cursor position matches the mouse position or the cursor can no longer move in that direction
# (this happens when the cursor reaches the start/end of the commandline).

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

# We aren't at the commandline so return
if [ "$(tmux display -p '#{==:#{pane_current_command},#{b:default-shell}}')" = '0' ]; then
  return
fi

mouse_x="$1"
mouse_y="$2"
cursor_x="$3"
cursor_y="$4"
session_id="$5"
window_id="$6"
pane_id="$7"
pane_pid="$8"

# If the shell is running a program, do nothing
if ps --ppid "$pane_pid" >/dev/null 2>&1; then
  return
fi

# The mouse is over the cursor already, nowhere to move
if [ "$mouse_x" = "$cursor_x" ] && [ "$mouse_y" = "$cursor_y" ]; then
  return
fi

direction="right"
if [ "$mouse_y" -lt "$cursor_y" ]; then
  direction='left'
elif [ "$mouse_y" -eq "$cursor_y" ] && [ "$mouse_x" -lt "$cursor_x" ]; then
  direction='left'
fi

max='1000'
while [ "$cursor_x" -ne "$mouse_x" ] || [ "$cursor_y" -ne "$mouse_y" ]; do
  prev_cursor_x="$cursor_x"
  prev_cursor_y="$cursor_y"

  tmux send-keys -t "${session_id}:${window_id}.${pane_id}" "$direction"
  cursor_x="$(tmux display -p '#{cursor_x}')"
  cursor_y="$(tmux display -p '#{cursor_y}')"
  if [ "$cursor_x" -eq "$prev_cursor_x" ] && [ "$cursor_y" -eq "$prev_cursor_y" ]; then
    break
  fi

  max=$((max - 1))
  if [ "$max" -le '0' ]; then
    break
  fi
done
