function fzf-apt-install-widget --description 'Install packages with apt'
  set choices \
      ( \
        FZF_DEFAULT_COMMAND='apt-cache pkgnames' \
         fzf-tmux -p 100% \
            --ansi \
            --multi \
            --bind "alt-enter:toggle,change:first" \
            --header '(alt+enter to multi-select)' \
            --prompt 'apt install: ' \
            --preview "apt show {} 2>/dev/null | GREP_COLORS='$GREP_COLORS' grep --color=always -E '(^[a-z|A-Z|-]*:|^)' | less" \
      )
  or return

  echo "Running command 'sudo apt-get install $choices'..."
  sudo apt-get install --assume-yes $choices
end
