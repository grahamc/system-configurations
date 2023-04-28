# Actions that should be run at the end of startup

if not status is-interactive
    exit
end

# Sets the cursor shape to a blinking bar
echo -ne '\033[5 q'

# Print banner
if not set --query BANNER_WAS_PRINTED
    set banner Fish Shell v(string split ' ' (fish --version) | tail -n 1)

    # If we don't have figlet, or the smblock font, fallback to echo. Doing it this way because I don't know how
    # to check for the existence of a figlet font so I'll have to just let it fail.
    figlet -W -f smblock $banner 2>/dev/null
    or echo $banner

    set --global --export BANNER_WAS_PRINTED
end

# Ask the user to connect to tmux.
# Wrapping this in a function so that I am able to exit early with 'return'
function _tmux_connect
    if test -n "$TMUX_CONNECT_WAS_RUN"
        return
    end
    # We use this variable to tell if this function ran.
    # The goal is to have it run once when a 'top-level' shell gets started, e.g. when you first
    # open a terminal, so we use two flags to get that effect:
    # - We use the global flag so that it is run once per shell instance.
    # - We use the export flag so that it isn't run in child shells.
    set --global --export TMUX_CONNECT_WAS_RUN 1

    # User is already in TMUX so no need to connect
    if test -n "$TMUX"
        return
    end

    set accent (set_color cyan)
    set normal (set_color normal)
    read --prompt "echo -n -s 'Welcome back $USER, would you like to connect to tmux? (' '$accent' 'y' '$normal' '/' '$accent' 'n' '$normal' '): ';" --nchars 1 response
    if test $response = y
        tmux attach-session
    end
end
if type --query tmux
    _tmux_connect
end

# Trigger direnv. This way if a terminal or tmux-pane gets spawned in a directory that has
# a .envrc file, it will get loaded automatically.
if type --query direnv
    direnv reload 2>/dev/null
    # Added this so that even if the previous command fails, this script won't return a non-zero exit code
    or true
end
