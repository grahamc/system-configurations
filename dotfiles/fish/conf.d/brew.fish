if not status is-interactive
    exit
end

abbr --add --global fbi 'fzf-brew-install-widget'
abbr --add --global fbu 'fzf-brew-uninstall-widget'
abbr --add --global bo 'brew outdated --fetch-HEAD'
set --global --export HOMEBREW_NO_INSTALL_UPGRADE 1

function fzf-brew-install-widget --description 'Install packages with brew'
  set choices \
    ( \
    FZF_DEFAULT_COMMAND='brew formulae' \
    FZF_HINTS='ctrl+o: search online' \
    fzf-tmux-zoom \
    --bind 'ctrl-o:preview(echo "Searching online...")+reload(brew search "" | tail -n +2)' \
    --prompt 'brew install ' \
    # fzf triggers its loading animation for the preview window if the command hasn't completed
    # and has outputted at least one line. To get a loading animation for the 'brew info' command
    # we first echo a blank line and then clear it.
    #
    # The grep command is to highlight the different section names in the output.
    --preview 'echo ""; printf "\033[2J"; HOMEBREW_COLOR=1 brew info {} | grep --color=always --extended-regexp --regexp "^.*:\ " --regexp "^"' \
    --preview-window '75%' \
    --tiebreak=chunk,begin,end \
    )
  or return

  echo "Running command 'brew install $choices'..."
  brew install $choices
end

function fzf-brew-uninstall-widget --description 'Uninstall packages with brew'
  set choices \
    ( \
      FZF_DEFAULT_COMMAND='brew leaves --installed-on-request' \
      fzf-tmux-zoom \
        --prompt 'brew uninstall ' \
        # fzf triggers its loading animation for the preview window if the command hasn't completed
        # and has outputted at least one line. To get a loading animation for the 'brew info' command
        # we first echo a blank line and then clear it.
        #
        # The grep command is to highlight the different section names in the output.
        --preview 'echo ""; printf "\033[2J"; HOMEBREW_COLOR=1 brew info {} | grep --color=always --extended-regexp --regexp "^.*:\ " --regexp "^"' \
        --preview-window '75%' \
        --tiebreak=chunk,begin,end \
    )
  or return

  echo "Running command 'brew uninstall $choices'..."
  brew uninstall $choices
end
