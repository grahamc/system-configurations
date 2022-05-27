function fzf-brew-install-widget --description 'Install packages with brew'
  set choices \
      ( \
        FZF_DEFAULT_COMMAND='brew formulae' \
         fzf-tmux -B -p 100% -- \
            --ansi \
            --multi \
            --bind 'alt-enter:toggle,change:first,ctrl-o:preview(echo "Searching online...")+reload(brew search "" | tail -n +2)' \
            --header '(alt+enter: multi-select, ctrl+o: search online)' \
            --prompt 'brew install: ' \
            --preview "HOMEBREW_COLOR=1 brew info {}" \
      )
  or return

  echo "Running command 'brew install $choices'..."
  brew install $choices
end
