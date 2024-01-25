#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# TODO: Ideally I would get my config file(s) straight from tmux with the command below, but the problem is that
# if my config file is a symlink, tmux will return the destination of the symlink and since I use nix to manage my
# config files, the destination of the symlink will change every time my nix generation changes. I should see if
# tmux would be willing to provide a way to get the symlink path instead of the destination path. In the meantime,
# I'll just hardcode it since it probably won't change anytime soon.
#
# tmux display-message -p "#{config_files}" | tr "," "\n" | xargs -I CONFIG tmux source-file CONFIG
tmux source-file "${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"

# Display an indicator to let the user know the config has reloaded. I added an extra space before 'RELOADED' so the
# indicator would take up as much space as the 'RELOADING' one
#
# `refresh-client -S` forces the status bar to redraw
#
# The `\;` lets us execute multiple tmux commands in a single call to tmux. We do this since it's faster than separate
# calls.
tmux \
  set @mode_indicator_custom_prompt "#[italics bg=#{@bgcolor} fg=default]   RELOADED    " \
  \; refresh-client -S

# We wait for the amount of time specfied in the tmux option `display-time`. This way the indicator stays up for the
# same amount of time as normal messages.
sleep $(($(tmux display -p "#{display-time}") / 1000))

# Remove the indicator.
#
# `refresh-client -S` forces the status bar to redraw
#
# The `\;` lets us execute multiple tmux commands in a single call to tmux. We do this since it's faster than separate
# calls.
tmux \
  set -u @mode_indicator_custom_prompt \
  \; refresh-client -S
