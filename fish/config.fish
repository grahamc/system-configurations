# Configuration file for the fish shell.
# A shell is either interactive or non-interactive and either login or non-login. This produces
# four different 'modes': interactive-login, interactive-non-login, non-interactive-login,
# and non-interactive-non-login. This file configures the shell appropriately
# based on the mode it's running in.
#
# DEFINITIONS:
########################################
#
# non-interactive - a shell that is run without passing the --interactive flag. It's called
# non-interactive since it runs commands from a script (e.g. 'fish path-to-script.fish')
# or from a string containing commands (e.g. 'fish --command "echo hi"'). This is in contrast to
# an interactive shell that gets its commands to run by prompting the user, like in a terminal.
#
# interactive - a shell started with the --interactive flag (e.g. fish --interactive).
# This type of shell prompts the user for commands to run. You can also give it a script to run
# and the shell will become interactive after running the script
# (e.g. 'fish --interactive path-to-script.fish').
#
# login - A shell started with the --login flag. This flag is used so that the shell
# can tell if it is being run as part of the login process. This way, the shell
# can run commands that should only be run once at login (like setting environment variables).
#
# non-login - A shell started without the --login flag.
#
# EXAMPLES:
########################################
#
# non-interactive-non-login mode - Used when running a script or one-off command.
#
# non-interactive-login mode - This usually gets created by a display manager (e.g. gnome display manager)
# after a user logs in through a GUI.
#
# interactive-non-login mode - Used when a user launches a terminal.
#
# interactive-login mode - This gets created when a user ssh's into a computer since the ssh developers
# consider it a form of logging in.
#
# More info: https://unix.stackexchange.com/questions/38175/difference-between-login-shell-and-non-login-shell

# Config for login shells i.e. shells started as part of the login process
if status is-login
    # Adding this to the PATH since this is where user-specific executables should go, per the
    # XDG Base Directory spec.
    # More info: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
    fish_add_path --prepend --global "$HOME/.local/bin"

    # Initialize brew
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
end

# Config for interactive shells e.g. shells in terminals
if status is-interactive
    abbr --add --global trash trash-put
    abbr --add --global t-sys sysz
    abbr --add --global r-asdf 'asdf reshim'
    abbr --add --global r-kitty 'killall --signal SIGUSR1 kitty'
    abbr --add --global g git
    abbr --add --global touchp touch-and-make-parent-dirs
    set --global --export PAGER less

    # reload the database used to search for applications
    abbr --add --global r-desktop-entries 'sudo update-desktop-database; update-desktop-database ~/.local/share/applications'

    # fish
    set --global --export fish_color_normal
    set --global --export fish_color_command
    set --global --export fish_color_quote green
    set --global --export fish_color_redirection
    set --global --export fish_color_end
    set --global --export fish_color_error red
    set --global --export fish_color_param
    set --global --export fish_color_comment black
    set --global --export fish_color_match
    set --global --export fish_color_search_match --background=brblack
    # TODO: I want to remove the default bolding, but currently only the background is configurable.
    # Issue: https://github.com/fish-shell/fish-shell/issues/2442
    set --global --export fish_pager_color_selected_background --background=brblack
    set --global --export fish_color_operator
    set --global --export fish_color_escape
    set --global --export fish_color_cwd
    set --global --export fish_color_autosuggestion blue
    set --global --export fish_color_user
    set --global --export fish_color_host
    set --global --export fish_pager_color_prefix cyan
    set --global --export fish_pager_color_completion
    set --global --export fish_pager_color_description
    set --global --export fish_pager_color_progress --background=brblack normal
    set --global --export fish_pager_color_secondary
    set --global --export fish_color_cancel black
    # reload this config file
    abbr --add --global r 'exec fish'
    # Don't print a greeting when a new interactive fish shell is started
    set --global --export fish_greeting ''
    # use ctrl+z to resume the most recently suspended job
    bind \cz fg
    # use ctrl+right-arrow to accept the next suggested word
    bind \e\[1\;3C forward-word
    # use ctrl+b to jump to beginning of line
    bind \cb beginning-of-line

    # sudo
    abbr --add --global s sudo

    # cloudflared
    abbr --add --global tunnel cloudflared-tunnel

    # ps
    abbr --add --global fp fzf-process-widget

    # man
    abbr --add --global fm fzf-man-widget

    # x server
    abbr --add --global r-xbindkeys 'killall xbindkeys; xbindkeys'
    abbr --add --global copy 'xclip -selection clipboard'
    abbr --add --global paste 'xclip -selection clipboard -out'

    # Set preferred editor.
    #
    # BACKGROUND: Historically, EDITOR referred to a line editor (e.g. ed) and
    # VISUAL referred to a fullscreen editor (e.g. vi), the latter requiring a more advanced
    # terminal. Programs could then attempt to run the VISUAL editor, and if it wasn't supported,
    # fall back to EDITOR. However, since practically all terminals today support a fullscreen (VISUAL)
    # editor, this distinction is no longer necessary.
    #
    # Since some programs just use the value in EDITOR without checking VISUAL, and vice-versa,
    # I set both to the same editor.
    # For more info: https://unix.stackexchange.com/questions/4859/visual-vs-editor-what-s-the-difference/302391#302391
    set --global --export VISUAL vim
    set --global --export EDITOR $VISUAL

    # Change the color grep uses for highlighting matches to magenta
    set --global --export GREP_COLORS 'ms=00;35'

    # Sets the cursor shape to a blinking bar
    echo -ne '\033[5 q'

    # ls
    abbr --add --global ls 'ls -x --color=never --classify --hyperlink=auto'
    # include hidden files
    abbr --add --global la 'ls -x --color=never --classify --almost-all --hyperlink=auto'
    # use the long format and a more human-readable format for sizes e.g. 25M
    abbr --add --global ll 'ls -x --color=never --classify -l --human-readable --hyperlink=auto'
    # combination of the the two above
    abbr --add --global lal 'ls -x --color=never --classify --almost-all -l --human-readable --hyperlink=auto'

    # cd
    abbr --add --global -- - 'cd -'

    # tmux
    abbr --add --global ta tmux-attach-or-create
    abbr --add --global r-tmux 'tmux source ~/.tmux.conf && tmux display-message "Reloaded TMUX..."'
    abbr --add --global r-tmux-plugins "$HOME/.tmux/plugins/tpm/bindings/install_plugins"
    abbr --add --global r-tmux-server reload-tmux-server

    # apt
    abbr --add --global ai 'sudo apt install'
    abbr --add --global ar 'sudo apt remove'
    abbr --add --global aar 'sudo apt autoremove'
    abbr --add --global aud 'sudo apt update'
    abbr --add --global aug 'sudo apt upgrade'
    abbr --add --global as apt-show
    abbr --add --global ap 'apt policy'
    abbr --add --global alu 'apt list --upgradeable'
    abbr --add --global ap 'sudo apt purge'
    abbr --add --global fai 'fzf-apt-install-widget'
    abbr --add --global far 'fzf-apt-remove-widget'

    # brew
    abbr --add --global fbi 'fzf-brew-install-widget'
    abbr --add --global fbu 'fzf-brew-uninstall-widget'
    abbr --add --global bo 'brew outdated'

    # asdf version manager
    source "$(brew --prefix asdf)/libexec/asdf.fish"

    # python
    # Don't add the name of the virtual environment to my prompt. This way, I can add it myself
    # using the same formatting as the rest of my prompt.
    set --global --export VIRTUAL_ENV_DISABLE_PROMPT 1

    # ripgrep
    set --global --export RIPGREP_CONFIG_PATH "$HOME/.ripgreprc"

    # zoxide
    set --global --export _ZO_FZF_OPTS "$FZF_DEFAULT_OPTS --preview 'ls --classify -x {2}' --keep-right --bind='change:first'"
    zoxide init --cmd cd fish | source

    # direnv
    direnv hook fish | source
    # toggle activation/deactivation messages
    abbr --add --global dirlog \
        'set --query DIRENV_LOG_FORMAT; and set --erase DIRENV_LOG_FORMAT; or set --global --export DIRENV_LOG_FORMAT'
    # disable activation/deactivation messages
    set --global --export DIRENV_LOG_FORMAT

    # vim
    abbr --add --global v vim

    # Ask the user to connect to tmux.
    # Wrapping this in a function so that I am able to exit early with 'return'
    function _tmux_connect
        if set --query TMUX_CONNECT_WAS_RUN
            return
        end
        # We use this variable to tell if this function ran.
        # The goal is to have it run once when a 'top-level' shell gets started, e.g. when you first
        # open a terminal, so we use two flags to get that effect:
        # - We use the global flag so that it is run once per shell instance.
        # - We use the export flag so that it isn't run in child shells.
        set --global --export TMUX_CONNECT_WAS_RUN

        # User is already in TMUX so no need to connect
        if test -n "$TMUX"
            return
        end

        type --query figlet
        and figlet -W -w (stty size | cut -d" " -f2) -f smblock Fish Shell v(string split ' ' (fish --version) | tail -n 1)
        echo "Welcome back $USER, would you like to connect to tmux? (y/n):"
        read --prompt 'echo "> "' --nchars 1 response
        if test $response = y
            tmux-attach-or-create
        end
    end
    _tmux_connect

    # Trigger direnv. This way if a terminal or tmux-pane gets spawned in a directory that has
    # a .envrc file, it will get loaded automatically.
    direnv reload 2>/dev/null
    # Added this so that even if the previous command fails, this script won't return a non-zero exit code
    or true
end
