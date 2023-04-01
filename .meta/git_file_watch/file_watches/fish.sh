#!/bin/sh

fish_plugins='fish/fish_plugins'
if has_changes "$fish_plugins"; then
  if confirm "The fish plugin file has changed, would you like fisher to update from it?"; then
    suppress_error fish -c 'source ~/.config/fish/functions/fisher.fish; fisher update'
  fi
fi

fish_function_pattern='fish/functions/*'
fish_conf_pattern='fish/conf.d/*'
if has_changes "$fish_function_pattern" || has_changes "$fish_conf_pattern"; then
  if confirm "A fish configuration or function has changed, would you like to reload all fish shells?"; then
    suppress_error fish -c 'set --universal _fish_reload_indicator (random)'
  fi
fi
