function fzf-apt-remove-widget --description 'Remove packages with apt'
  set choices \
      ( \
        FZF_DEFAULT_COMMAND='dpkg-query -W -f=\'${binary:Package}\n\'' \
        FZF_HINTS='alt+enter: select multiple items' \
        fzf-tmux-zoom \
            --ansi \
            --multi \
            --bind "alt-enter:toggle,change:first" \
            --prompt 'apt remove: ' \
            --preview "echo -e \"\$(apt show {} 2>/dev/null)\n\$(apt-cache rdepends --installed --no-recommends --no-suggests {} | tail -n +2)\" | GREP_COLORS='$GREP_COLORS' grep --color=always -E '(^[a-z|A-Z|-]*:|^.*:\$|^)' | less" \
            --tiebreak=chunk,begin,end \
      )
  or return

  echo "Running command 'sudo apt-get remove $choices'..."
  sudo apt-get remove --assume-yes $choices
end
