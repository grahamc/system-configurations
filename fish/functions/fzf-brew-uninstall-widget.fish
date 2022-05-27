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
            # fzf triggers its loading animation for the preview window if the command hasn't completed
            # and has outputted at least one line. To get a loading animation for the 'brew info' command
            # we first echo a blank line and then clear it.
            --preview 'echo ""; printf "\033[2J"; HOMEBREW_COLOR=1 brew info {}' \
      )
  or return

  echo "Running command 'brew uninstall $choices'..."
  brew uninstall $choices
end
