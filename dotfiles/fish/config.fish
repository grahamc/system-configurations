# Actions that should be run at the end of startup

if not status is-interactive
    exit
end

# Sets the cursor shape to a blinking bar
printf '\033[5 q'

# I don't want to use this variable. Only thing I know that sets this is the Determinate Systems Nix
# installer
set fish_user_paths

# TODO: The Determinate Systems Nix installer adds nix to the $PATH even if the shell wasn't
# launched in login mode. Specifically:
#   - Its fish config is not guarded by a login-mode check
#   - Its zsh config is in /etc/zshrc which gets run whenever zsh is interactive, regardless
#   of whether or not it is in login mode
#
# This may result in duplicates so to get around that, I'm going to try to remove the extra
# prepended entries by deduplicating the whole path, favoring later entries. I'm doing it this way
# to to avoid hardcoding the paths they add.
#
# Maybe I should ask them if this behavior should be changed by adding a login-mode guard or only
# adding the $PATH entries if they aren't already present.
if not status is-login
    set new_path
    for path in (printf '%s\n' $PATH | tac)
        if not contains $path $new_path
            set --prepend new_path $path
        end
    end
    set PATH $new_path
end

# Print banner
if not set --query BANNER_WAS_PRINTED
    set banner Fish Shell v(string split ' ' (fish --version) | tail -n 1)
    figlet -W -f smblock $banner
    set --global --export BANNER_WAS_PRINTED
end

# Ask the user to connect to tmux.
# Wrapping this in a function so that I am able to exit early with 'return'
function tmux_attach
    if test -n "$TMUX_CONNECT_WAS_RUN"
        return
    end
    # We use this variable to tell if this function ran.
    # The goal is to have it run once when a 'top-level' shell gets started, e.g. when you first
    # open a terminal, so we use two flags to get that effect:
    # - We use the global flag so that it is run once per shell instance.
    # - We use the export flag so that it isn't run in child shells.
    set --global --export TMUX_CONNECT_WAS_RUN 1

    set accent (set_color cyan)
    set normal (set_color normal)

    set user ''
    if test -n "$USER"
        set user " $USER"
    end
    read --prompt-str "Hey$user, would you like to connect to tmux? ($accent""y$normal/$accent""n$normal): " --nchars 1 response
    if test $response = y
        tmux attach-session
    end
end
if test -z "$TMUX"
    if set --query VSCODE_INJECTION
        # FIF doesn't work when I attach to tmux
        # issue: https://github.com/tomrijndorp/vscode-finditfaster/issues/65
        # TODO: I think it's because `set -u` is being set, per the error in the issue
        if not set --query FIND_IT_FASTER_ACTIVE
            tmux-attach-to-project
        end
    else
        tmux_attach
    end
end
