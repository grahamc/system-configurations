#!/usr/bin/env sh

if has_changes 'tmux/tmux.conf'; then
  if confirm "The tmux configuration has changed, would you like to reload tmux?"; then
    suppress_error tmux source-file ~/.config/tmux/tmux.conf
  fi
fi
