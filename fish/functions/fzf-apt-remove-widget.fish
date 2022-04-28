function fzf-apt-remove-widget --description 'Remove packages with apt'
  set choices \
      ( \
        FZF_DEFAULT_COMMAND='dpkg-query -W -f=\'${binary:Package}\n\'' \
        fzf-tmux -B -p 100% -- \
            --ansi \
            --multi \
            --bind "alt-enter:toggle,change:first" \
            --header '(alt+enter to multi-select)' \
            --prompt 'apt remove: ' \
            --preview "apt show {} 2>/dev/null | GREP_COLORS='$GREP_COLORS' grep --color=always -E '(^[a-z|A-Z|-]*:|^)' | less" \
      )
  or return

  echo "Running command 'sudo apt-get remove $choices'..."
  sudo apt-get remove --assume-yes $choices
end
