#!/usr/bin/env bash

# Move the commandline cursor to where the mouse was clicked.

# DEBUG
# tmux only displays stdout so redirect errors there
exec 2>&1

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

# If the current program isn't the shell then exit
if [ "$(tmux display -p '#{==:#{pane_current_command},#{b:default-shell}}')" = '0' ]; then
  exit
fi

mouse_x="$1"
mouse_y="$2"
cursor_x="$3"
cursor_y="$4"
session_id="$5"
window_id="$6"
pane_id="$7"
pane_pid="$8"

# If the shell is running a program then exit.
if pgrep -q -P "$pane_pid"; then
  exit
fi

# If the mouse is over the cursor already, there's nothing to do so exit.
if [ "$mouse_x" = "$cursor_x" ] && [ "$mouse_y" = "$cursor_y" ]; then
  exit
fi

# Fastest algorithm. Start from the beginning of the commandline and iterate through both the commandline returned
# by fish and the screen lines returned by tmux that contain the commandline. We need both because some shells, like
# fish, insert indentation that is solely visible and won't be returned with the commandline, but tmux has the raw
# screen line so it will include the indentation. As we iterate through both we keep track of the distance between
# where the cursor is and where the mouse was clicked so we know how many left/right presses to generate. Sometimes
# we'll hit a character in the tmux screen lines that isn't in the fish commandline, like the visual indentation
# described above or a newline character when the terminal soft wraps the commandline, so in those cases we advance
# the tmux pointer, but not the fish one.
#
# This one accounts for all the edge cases in the other two algorithms.
########################################
# if ! [ -p /tmp/fish-tmux-commandline ]; then
#   mkfifo /tmp/fish-tmux-commandline
# fi
# kill -USR2 "$pane_pid"
# # TODO: sometimes the commandline doesn't get send through, I get an empty string or it's incomplete. I tried
# # comparing what I get from the fifo with what I get from using a binding and at first the fifo would be incomplete,
# # but when I call the binding it has the full commandline and if I try the fifo again it will also have the full
# # commandline. Think it has to do with calling commandline from a signal handler because the bind seems to be
# # reliable. Maybe a cache that needs to be invalidated.
# if ! commandline="$(timeout 1s cat /tmp/fish-tmux-commandline)"; then
#   exit
# fi
# commandline_start_y="$(tmux display -p '#{@prompt_y}')"
# tmux_lines="$(tmux capture-pane -S "$commandline_start_y" -E - -p -T)"
# # this will be 1 less than the line count so if there is one line this will be 0
# commandline_line_count="$(printf '%s' "$tmux_lines" | wc -l)"
# commandline_end_y="$((commandline_start_y + commandline_line_count))"

# # DEBUG
# # printf "commandline: \n %s\n" "|${commandline}|"
# # echo "commandline_start_y: $commandline_start_y"
# # printf "tmux_lines: \n %s\n" "|${tmux_lines}|"
# # echo "commandline_line_count: $commandline_line_count"
# # echo "commandline_end_y: $commandline_end_y"

# # If the y coordinate for the mouse click is above or below the commandline then we exit since there is no way
# # the mouse click was on the contents of the commandline.
# if [ "$mouse_y" -lt "$commandline_start_y" ] || [ "$mouse_y" -gt "$commandline_end_y" ]; then
#   exit
# fi

# prompt_start_x="$(tmux display -p '#{@prompt_x}')"
# tmux_cur="$prompt_start_x"
# fish_cur=0
# cur_x="$prompt_start_x"
# cur_y="$commandline_start_y"
# reached_mouse=''
# reached_cursor=''
# move_count=0
# commandline_length="$(printf '%s' "$commandline" | wc -c)"

# # DEBUG
# # echo "tmux_cur: $tmux_cur"
# # echo "fish_cur: $fish_cur"
# # echo "cur_x: $cur_x"
# # echo "cur_y: $cur_y"
# # echo "reached_mouse: $reached_mouse"
# # echo "reached_cursor: $reached_cursor"
# # echo "move_count: $move_count"
# # echo "commandline_length: $commandline_length"
# # echo

# max=0
# while [ "$fish_cur" -ne "$commandline_length" ] && [ "$max" -ne 1000 ]; do
#   max="$((max + 1))"
#   # DEBUG
#   # printf "ITERATION\n#########################################\n"

#   fish_char="${commandline:fish_cur:1}"
#   tmux_char="${tmux_lines:tmux_cur:1}"

#   # If we've reached the mouse or cursor and we are iterating over a character that is actually part of the commandline,
#   # meaning the cursor can move over it (unlike visual indentation or soft wraps), then we should add 1 to the move
#   # count.
#   if [ "$fish_char" = "$tmux_char" ]; then
#     if [ -n "$reached_cursor" ] || [ -n "$reached_mouse" ]; then
#       move_count="$((move_count + 1))"
#     fi
#   fi

#   if [ "$cur_x" = "$mouse_x" ] && [ "$cur_y" = "$mouse_y" ]; then
#     reached_mouse=1
#   elif [ "$cur_x" = "$cursor_x" ] && [ "$cur_y" = "$cursor_y" ]; then
#     reached_cursor=1
#   fi

#   # DEBUG
#   # echo "fish_char: $fish_char"
#   # echo "tmux_char: $tmux_char"
#   # echo "move_count: $move_count"
#   # echo "reached_mouse: $reached_mouse"
#   # echo "reached_cursor: $reached_cursor"

#   if [ -n "$reached_cursor" ] && [ -n "$reached_mouse" ]; then
#     break
#   fi

#   if [ "$fish_char" != "$tmux_char" ]; then
#     # must be visual indentation added by the shell or newline from soft line wrap
#     tmux_cur="$((tmux_cur + 1))"
#   else
#     tmux_cur="$((tmux_cur + 1))"
#     fish_cur="$((fish_cur + 1))"
#   fi
#   if [ "$tmux_char" = $'\n' ]; then
#     cur_x=0
#     cur_y="$((cur_y + 1))"
#   else
#     cur_x="$((cur_x + 1))"
#   fi

#   # DEBUG
#   # echo "tmux_cur: $tmux_cur"
#   # echo "fish_cur: $fish_cur"
#   # echo "cur_x: $cur_x"
#   # echo "cur_y: $cur_y"
#   # echo
# done

# # If the cursor is at the end of the commandline or the mouse click was past the end of the commandline, we
# # need to add 1 to the move count.
# #
# # We'll only hit one of the above cases if `fish_cur` hits the end of the commandline, hence this first check.
# if [ "$fish_cur" -eq "$commandline_length" ]; then
#   if [ "$cur_x" -eq "$cursor_x" ] || [ "$cur_x" -le "$mouse_x" ]; then
#     move_count="$((move_count + 1))"
#   fi
# fi

# direction="right"
# if [ "$mouse_y" -lt "$cursor_y" ]; then
#   direction='left'
# elif [ "$mouse_y" -eq "$cursor_y" ] && [ "$mouse_x" -lt "$cursor_x" ]; then
#   direction='left'
# fi

# tmux send-keys -t "${session_id}:${window_id}.${pane_id}" -N "$move_count" "$direction"

# Faster algorithm. Based on the index of the cursor in the commandline contents string, we can determine the index
# to set the cursor to so that is has the correct y coordinate. We'll position it at the beginning of the correct
# line and then move to the right until we hit the right x coordinate or hit the end of the line.
#
# NOTE: This algorithm won't work with wrapped lines. Though it does do a no-op on clicks outside the commandline
# unlike the slow algorithm.
########################################
if ! [ -p /tmp/fish-tmux-commandline ]; then
  mkfifo /tmp/fish-tmux-commandline
fi
if ! [ -p /tmp/fish-tmux-cursor ]; then
  mkfifo /tmp/fish-tmux-cursor
fi
kill -USR2 "$pane_pid"
# TODO: sometimes the commandline doesn't get send through, I get an empty string or it's incomplete. I tried
# comparing what I get from the fifo with what I get from using a binding and at first the fifo would be incomplete,
# but when I call the binding it has the full commandline and if I try the fifo again it will also have the full
# commandline. Think it has to do with calling commandline from a signal handler because the bind seems to be
# reliable. Maybe a cache that needs to be invalidated.
#
# I also get incorrect values for the cursor, probably for the same reason as the commandline explained above.
cursor_index="$(timeout 1s cat /tmp/fish-tmux-cursor)"
commandline="$(timeout 1s cat /tmp/fish-tmux-commandline)"
commandline_line_count="$(printf '%s' "$commandline" | wc -l)"
commandline_length="$(printf '%s' "$commandline" | wc -c)"
commandline_start_y="$(tmux display -p '#{@prompt_y}')"
commandline_end_y="$((commandline_start_y + commandline_line_count))"
# If the y coordinate for the mouse click is above or below the commandline then we exit since there is no way
# the mouse click was on the contents of the commandline.
if [ "$mouse_y" -lt "$commandline_start_y" ] || [ "$mouse_y" -gt "$commandline_end_y" ]; then
  exit
fi
if [ "$cursor_y" -ne "$mouse_y" ]; then
  if [ "$cursor_y" -gt "$mouse_y" ]; then
    cur="$cursor_index"
    # HACK: limit should be 0, but since the cursor index isn't reliable (see above TODO) I'll increase the limit.
    limit=-500
    newlines_required="$((cursor_y - mouse_y))"
    while [ "$cur" -ne "$limit" ] && [ "$newlines_required" -gt 0 ]; do
      cur="$((cur - 1))"
      if [ "${commandline:cur:1}" = "\n" ]; then
        newlines_required="$((newlines_required - 1))"
      fi
    done
    tmux send-keys -t "${session_id}:${window_id}.${pane_id}" -N "$((cursor_index - cur))" left
  else
    cur="$cursor_index"
    # HACK: limit should be `$commandline_length`, but since the cursor index isn't reliable (see above TODO) I'll increase the limit.
    limit="500"
    newlines_required="$((mouse_y - cursor_y))"
    while [ "$cur" -ne "$limit" ] && [ "$newlines_required" -gt 0 ]; do
      cur="$((cur + 1))"
      if [ "${commandline:cur:1}" = "\n" ]; then
        newlines_required="$((newlines_required - 1))"
      fi
    done
    tmux send-keys -t "${session_id}:${window_id}.${pane_id}" -N "$((cur - cursor_index))" right
  fi

  # Get the new cursor coordinates. This is because we can't be sure of what the x coordinate will be since some
  # shells, like fish, insert indentation on multiline commandlines.
  cursor_x="$(tmux display -p '#{cursor_x}')"
  cursor_y="$(tmux display -p '#{cursor_y}')"
fi

if [ "$cursor_x" -ne "$mouse_x" ]; then
  if [ "$cursor_x" -gt "$mouse_x" ]; then
    tmux send-keys -t "${session_id}:${window_id}.${pane_id}" -N "$((cursor_x - mouse_x))" left
  else
    tmux send-keys -t "${session_id}:${window_id}.${pane_id}" -N "$((mouse_x - cursor_x))" right
  fi
fi

# Slow algorithm. Keep sending left/right arrow key presses into the pane until the cursor x/y coordinates match
# up with that of the mouse click or until we hit the start/end of the commandline.
#
# This one can be annoying because it isn't aware of which lines the commandline is on. This means if you click
# anywhere on the screen it tries to get the cursor there.
########################################
# direction="right"
# if [ "$mouse_y" -lt "$cursor_y" ]; then
#   direction='left'
# elif [ "$mouse_y" -eq "$cursor_y" ] && [ "$mouse_x" -lt "$cursor_x" ]; then
#   direction='left'
# fi
#
# max='1000'
# while [ "$cursor_x" -ne "$mouse_x" ] || [ "$cursor_y" -ne "$mouse_y" ]; do
#   prev_cursor_x="$cursor_x"
#   prev_cursor_y="$cursor_y"
#
#   tmux send-keys -t "${session_id}:${window_id}.${pane_id}" "$direction"
#   cursor_x="$(tmux display -p '#{cursor_x}')"
#   cursor_y="$(tmux display -p '#{cursor_y}')"
#   if [ "$cursor_x" -eq "$prev_cursor_x" ] && [ "$cursor_y" -eq "$prev_cursor_y" ]; then
#     break
#   fi
#
#   max=$((max - 1))
#   if [ "$max" -le '0' ]; then
#     break
#   fi
# done
