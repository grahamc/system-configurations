function fzf-brew-uninstall-widget --description 'Uninstall packages with brew'
  set choices \
      ( \
        FZF_DEFAULT_COMMAND='brew leaves' \
        fzf-tmux -B -p 100% -- \
            --ansi \
            --multi \
            --bind "alt-enter:toggle,change:first" \
            --header '(alt+enter to multi-select)' \
            --prompt 'brew uninstall: ' \
            --preview "HOMEBREW_COLOR=1 brew info {}" \
      )
  or return

  echo "Running command 'brew uninstall $choices'..."
  brew uninstall $choices
end
