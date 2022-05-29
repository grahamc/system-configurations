function fzf-apt-install-widget --description 'Install packages with apt'
  set choices \
      ( \
        FZF_DEFAULT_COMMAND='apt-cache pkgnames' \
        fzf-tmux -B -p 100% -e "FZF_HINTS=alt+enter: select multiple items" -- \
            --ansi \
            --multi \
            --bind "alt-enter:toggle,change:first" \
            --prompt 'apt install: ' \
            --preview "apt show {} 2>/dev/null | GREP_COLORS='$GREP_COLORS' grep --color=always -E '(^[a-z|A-Z|-]*:|^)' | less" \
      )
  or return

  echo "Running command 'sudo apt-get install $choices'..."
  sudo apt-get install --assume-yes $choices
end
