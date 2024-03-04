# Actions that should be run at the end of startup

if not status is-interactive
    exit
end

# Sets the cursor shape to a blinking bar
printf '\033[5 q'

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
    else if env | grep -q -E '^VSCODE'
        # HACK: vscode doesn't set VSCODE_INJECTION when launching a terminal when debugging so instead
        # I'm looking for any variable that starts with VSCODE. This is actually ideal for me because
        # currently some garbage gets printed to screen whenever I first connect to tmux from vscode
        # which gets executed as part of the debugger command, causing it to fail. Since I can tell when
        # a debug session is being started, I won't connect to TMUX in that case.
        #
        # TODO: I should report this error. Might be related to this:
        # https://github.com/tmux/tmux/issues/3470
        :
    else
        tmux_attach
    end
end
