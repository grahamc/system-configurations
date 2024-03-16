# Actions that should be run at the end of startup

if not status is-interactive
    exit
end

# Sets the cursor shape to a blinking bar
printf '\033[5 q'

# Print banner, unless we're in vscode
#
# HACK: vscode doesn't set VSCODE_INJECTION when launching a terminal when debugging so instead
# I'm looking for any variable that starts with VSCODE. Should probably report this.
if not env | grep -q -E '^VSCODE'
    if not set --query BANNER_WAS_PRINTED
        set banner Fish Shell v(string split ' ' (fish --version) | tail -n 1)
        figlet -W -f smblock $banner
        set --global --export BANNER_WAS_PRINTED
    end
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
    # HACK: vscode doesn't set VSCODE_INJECTION when launching a terminal when debugging so instead
    # I'm looking for any variable that starts with VSCODE. Should probably report this.
    if env | grep -q -E '^VSCODE'
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
