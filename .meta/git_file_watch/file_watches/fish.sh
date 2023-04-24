#!/usr/bin/env sh

fish_function_pattern='fish/functions/*'
fish_conf_pattern='fish/conf.d/*'
if has_changes "$fish_function_pattern" || has_changes "$fish_conf_pattern"; then
  if confirm "A fish configuration or function has changed, would you like to reload all fish shells?"; then
    suppress_error fish -c 'set --universal _fish_reload_indicator (random)'
  fi
fi
