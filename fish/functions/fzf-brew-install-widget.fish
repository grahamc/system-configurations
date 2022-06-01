function fzf-brew-install-widget --description 'Install packages with brew'
  set choices \
      ( \
        FZF_DEFAULT_COMMAND='brew formulae' \
        FZF_HINTS='alt+enter: select multiple items\nctrl+o: search online' \
        fzf-tmux-zoom \
            --ansi \
            --multi \
            # fzf triggers its loading animation for the preview window if the command hasn't completed
            # and it has outputted at least one line. To get a loading animation for the
            # 'brew search' command, we first echo a line of text and then enter an infinite loop.
            # When brew is done, the preview window will get updated and the previous preview command
            # with the infinite loop will be stopped. The inifinite loop contains a sleep command so that
            # we don't have to execute the loop conditional as much.
            --bind 'alt-enter:toggle,change:first,ctrl-o:preview(echo "Searching online..."; while :; sleep 1000; end)+reload(brew search "" | tail -n +2)' \
            --prompt 'brew install: ' \
            # fzf triggers its loading animation for the preview window if the command hasn't completed
            # and has outputted at least one line. To get a loading animation for the 'brew info' command
            # we first echo a blank line and then clear it.
            #
            # The grep command is to highlight the different section names in the output.
            --preview 'echo ""; printf "\033[2J"; HOMEBREW_COLOR=1 brew info {} | grep --color=always --extended-regexp --regexp "^.*:\ " --regexp "^"' \
      )
  or return

  echo "Running command 'brew install $choices'..."
  brew install $choices
end
