if not status is-interactive
    or test (uname) != Darwin
    or not type --query brew
    exit
end

abbr --add --global biw brew-install-widget
abbr --add --global buw brew-uninstall-widget

# nix-darwin manages brew so I'll turn off all the automatic management.
set --global --export HOMEBREW_NO_INSTALL_UPGRADE 1
set --global --export HOMEBREW_NO_INSTALL_CLEANUP 1

# autocomplete
if test -d $HOMEBREW_PREFIX/share/fish/completions
    set --global --prepend fish_complete_path $HOMEBREW_PREFIX/share/fish/completions
end
if test -d $HOMEBREW_PREFIX/share/fish/vendor_completions.d
    set --global --prepend fish_complete_path $HOMEBREW_PREFIX/share/fish/vendor_completions.d
end

function brew-install-widget --description 'Install packages with brew'
    if not set choices ( \
        FZF_DEFAULT_COMMAND='brew formulae' \
        FZF_HINTS='ctrl+alt+o: search online' \
        fzf-zoom \
        --bind 'ctrl-alt-o:preview(echo "Searching online...")+reload(brew search "" | tail -n +2)' \
        --prompt 'brew install ' \
        # fzf triggers its loading animation for the preview window if the command hasn't completed
        # and has outputted at least one line. To get a loading animation for the 'brew info' command
        # we first echo a blank line and then clear it.
        #
        # The grep command is to highlight the different section names in the output.
        --preview 'echo ""; printf "\033[2J"; HOMEBREW_COLOR=1 brew info {} | grep --color=always --extended-regexp --regexp "^.*: " --regexp "^"' \
        --preview-window '75%' \
        --tiebreak=chunk,begin,end \
    )
        return
    end

    echo "Running command 'brew install $choices'..."
    brew install $choices
end

function brew-uninstall-widget --description 'Uninstall packages with brew'
    if not set choices ( \
      FZF_DEFAULT_COMMAND='brew leaves --installed-on-request; brew ls --cask' \
      fzf-zoom \
        --prompt 'brew uninstall ' \
        # fzf triggers its loading animation for the preview window if the command hasn't completed
        # and has outputted at least one line. To get a loading animation for the 'brew info' command
        # we first echo a blank line and then clear it.
        #
        # The grep command is to highlight the different section names in the output.
        --preview 'echo ""; printf "\033[2J"; HOMEBREW_COLOR=1 brew info {} | grep --color=always --extended-regexp --regexp "^.*: " --regexp "^"' \
        --preview-window '75%' \
        --tiebreak=chunk,begin,end \
    )
        return
    end

    echo "Running command 'brew uninstall $choices'..."
    brew uninstall $choices
end
