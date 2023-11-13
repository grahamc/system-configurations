#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

tmux display-message -p "#{config_files}" | tr "," "\n" | xargs -I CONFIG tmux source-file CONFIG

# Display an indicator to let the user know the config has reloaded. I added an extra space before 'RELOADED' so the
# indicator would take up as much space as the 'RELOADING' one
#
# `refresh-client -S` forces the status bar to redraw
#
# The `\;` lets us execute multiple tmux commands in a single call to tmux. We do this since it's faster than separate
# calls.
tmux \
  set @mode_indicator_custom_prompt "#[bold bg=#{@bgcolor} fg=#{@standoutcolor} align=centre]#{@left_symbol}#[reverse]#{@checkmark_symbol}  RELOADED#[noreverse]#{@right_symbol}" \
  \; refresh-client -S

# We wait for the amount of time specfied in the tmux option `display-time`. This way the indicator stays up for the
# same amount of time as normal messages.
sleep $(( $(tmux display -p "#{display-time}") / 1000 ))

# Remove the indicator.
#
# `refresh-client -S` forces the status bar to redraw
#
# The `\;` lets us execute multiple tmux commands in a single call to tmux. We do this since it's faster than separate
# calls.
tmux \
  set -u @mode_indicator_custom_prompt \
  \; refresh-client -S

