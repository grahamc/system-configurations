if not status is-interactive
    exit
end

if not uname | grep -q Darwin
  exit
end

abbr --add --global fbi 'fzf-brew-install-widget'
abbr --add --global fbu 'fzf-brew-uninstall-widget'
abbr --add --global bo 'brew outdated --fetch-HEAD'

# nix-darwin manages brew so I'll turn off all the automatic management.
export HOMEBREW_NO_INSTALL_UPGRADE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_AUTO_UPDATE=1

# autocomplete
if test -d (brew --prefix)"/share/fish/completions"
    set -global --prepend fish_complete_path (brew --prefix)/share/fish/completions
end
if test -d (brew --prefix)"/share/fish/vendor_completions.d"
    set --global --prepend fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
end

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
