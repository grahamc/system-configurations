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

# Config for non-interactive shells e.g. shells running scripts.
if not status is-interactive
    # WARNING: To be safe, all code should be put inside this 'begin' block.
    # Reason being, the code in this conditional gets run when fish is running a script so the output
    # could break a script that expects certain content, or no content, in stdout or stderr.
    # By using a block, I can supress any of its output to stdout or stderr.
    #
    # For an example of how output could break ssh/scp/rsync, see the following link:
    # https://fishshell.com/docs/current/faq.html#why-won-t-ssh-scp-rsync-connect-properly-when-fish-is-my-login-shell
    begin
        # Do not load user functions. This is because I often have functions with the same name
        # as common commands and I don't want scripts to accidentally use them.
        set xdg_config_home
        if set --query XDG_CONFIG_HOME
            set xdg_config_home $XDG_CONFIG_HOME
        else
            set xdg_config_home "$HOME/.config"
        end
        set -l user_fish_functions_directory "$xdg_config_home/fish/functions"
        set -l index (contains --index $user_fish_functions_directory $fish_function_path)
        if test -n "$index"
            set --erase fish_function_path[$index]
        end
    end >/dev/null 2>/dev/null
end

# Config for login shells i.e. shells started as part of the login process
if status is-login
    # Adding this to the PATH since this is where user-specific executables should go, per the
    # XDG Base Directory spec.
    # More info: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
    fish_add_path --prepend --global "$HOME/.local/bin"
end

# Config for interactive shells e.g. shells in terminals
if status is-interactive
    # By default, fish calls the function 'fish_user_key_bindings', if it exists, after this config
    # gets loaded. This means any key bindings set in 'fish_user_key_bindings' will override keybinds
    # set in this file. I would prefer it if keybinds here would override keybinds in 'fish_user_key_bindings'.
    # This way I can change the default keybinds for tools like fzf.
    #
    # To do this, I call fish_user_key_bindings right now, if it exists, and then erase the function
    # so that fish doesn't call it later.
    set fish_keybind_function_name fish_user_key_bindings
    if functions --query $fish_keybind_function_name
        eval $fish_keybind_function_name
        functions --erase $fish_keybind_function_name
    end

    # Initialize brew. Doing this now since some of the tools used in this file may be installed with brew
    # and they won't be on the PATH until brew gets initialized.
    # TODO: Move to login shell initialization for the reason above.
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

    # Load navi widget. I'm doing this now since part of loading navi is setting a keybind (ctrl+g)
    # that would overwrite one of my keybinds. By doing this first, navi's keybind will be
    # the one that gets overwritten. Instead I'll use ctrl+n.
    navi widget fish | source
    bind \cn _navi_smart_replace

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
    # bash-style history expansion (!! and !$)
    function _bind_bang
        switch (commandline -t)
            case "!"
                commandline -t -- $history[1]
                commandline -f repaint
            case "*"
                commandline -i !
        end
    end
    function _bind_dollar
        switch (commandline -t)
            # Variation on the original, vanilla "!" case
            # ===========================================
            #
            # If the `!$` is preceded by text, search backward for tokens that
            # contain that text as a substring. E.g., if we'd previously run
            #
            #   git checkout -b a_feature_branch
            #   git checkout main
            #
            # then the `fea!$` in the following would be replaced with
            # `a_feature_branch`
            #
            #   git branch -d fea!$
            #
            # and our command line would look like
            #
            #   git branch -d a_feature_branch
            #
            case "*!"
                commandline -f backward-delete-char history-token-search-backward
            case "*"
                commandline -i '$'
        end
    end
    bind ! _bind_bang
    bind '$' _bind_dollar
    # transient prompt. Ideally I'd do this with a preexec hook, but that won't work for reasons outlined
    # in this issue: https://github.com/fish-shell/fish-shell/issues/7602#issuecomment-831601418
    # rebind enter so that before executing the commandline it redraws the prompt as a transient prompt
    function _load_transient_prompt_and_execute
        # If the pager is open, that means I am selecting an item, like an autocomplete suggestion.
        # In which case, I do not want to load a transient prompt.
        if not commandline --paging-mode
            set commandline_contents (commandline)
            # I use --valid so that the prompt doesn't become transient while I'm entering a multiline
            # command
            if commandline --is-valid
                set --global TRANSIENT
                commandline -f repaint
            # Make a distinction for an empty commandline. With this, I could insert a blank
            # line when the commandline is empty, giving me a way to separate commands visually
            else if test -z "$commandline_contents"
                set --global TRANSIENT_EMPTY
                commandline -f repaint
            end
        end
        commandline -f execute
    end
    bind \r _load_transient_prompt_and_execute
    # rebind ctrl+c so that before cancelling the commandline it redraws the prompt as a transient prompt
    function _load_transient_prompt_and_cancel
        set --global TRANSIENT
        commandline -f repaint
        commandline -f cancel-commandline
        commandline -f repaint
    end
    bind \cc _load_transient_prompt_and_cancel
    # rebind ctrl+d so that before exiting the shell it redraws the prompt as a transient prompt
    function _delete_or_load_transient_prompt_and_exit
        if test -n "$(commandline)"
            commandline -f delete-char
            return
        end

        set --global TRANSIENT
        commandline -f repaint

        # I do this instead of 'commandline -f exit' so that this way the word exit will be left on the previous prompt
        # instead of it just being blank. This way it's clear that the previous command was to exit from a shell.
        commandline --replace 'exit'
        commandline -f execute

        commandline -f repaint
    end
    bind \cd _delete_or_load_transient_prompt_and_exit
    end
    # use ctrl+b to jump to beginning of line
    bind \cb beginning-of-line
    # autoreload fish when a configuration file is modified
    set --query _autoreload_indicator
    or set --universal _autoreload_indicator 1
    function _autoreload_fish --on-variable _autoreload_indicator
        exec fish
    end
    set xdg_config_home
    if set --query XDG_CONFIG_HOME
    set xdg_config_home $XDG_CONFIG_HOME
    else
    set xdg_config_home "$HOME/.config"
    end
    set fish_config_path "$xdg_config_home/fish/"
    flock --nonblock /tmp/fish-autoreload-lock --command "find $fish_config_path | entr -nps 'fish -c \"set --universal _autoreload_indicator (math -1 \* \$_autoreload_indicator)\"'" > /dev/null &
    # If flock can't acquire the lock then the background job exits immediately and there will be nothing to disown
    # so disown will print an error which is why we suppress error output.
    #
    # TODO: If there was another background job started before we attempt to acquire this lock and flock could
    # not acquire this lock, disown would probably disown the wrong job
    disown 2> /dev/null

    # sudo
    abbr --add --global s sudo

    # cloudflared
    abbr --add --global tunnel cloudflared-tunnel

    # ps
    abbr --add --global fp fzf-process-widget

    # fzf
    set --global --export FZF_TMUX_OPTS '-p 100%'
    bind \cg 'fzf-grep-widget; commandline -f repaint'
    set --global --export FZF_DEFAULT_OPTS "
        --cycle
        --ellipsis='…'
        --bind tab:down,shift-tab:up,alt-down:last,alt-up:first
        --layout=reverse
        --color='16,bg+:-1,fg+:-1:regular,bg+:8,info:black,gutter:bright-black,pointer:14:regular,prompt:14:regular,border:black,query:-1:regular,marker:14:regular,header:black,spinner:14,hl:cyan,hl+:regular:cyan'
        --margin=7%
        --height 100%
        --prompt='> '
        --info='inline'
        --pointer='❯'
        --marker='❯'
        --history='$HOME/.fzf.history'
        --preview-window=wrap,bottom,border-top"
    set --global --export FZF_ALT_C_COMMAND "rg --files --null | xargs -0 dirname | sort -u"
    set --global --export FZF_ALT_C_OPTS "--preview 'ls --classify -C {}' --keep-right --bind='change:first'"
    set --global --export FZF_CTRL_T_COMMAND 'rg --files'
    set --global --export FZF_CTRL_T_OPTS '--multi --preview "bat --paging=never --terminal-width (math $FZF_PREVIEW_COLUMNS - 2) {} | tail -n +2 | head -n -1" --keep-right --bind="change:first"'
    set --global --export FZF_CTRL_R_OPTS '--prompt="history: " --preview "echo {}" --preview-window=33%'
    # use ctrl+f for file search instead of default ctrl+t
    bind --erase \ct
    bind \cf 'FZF_CTRL_T_OPTS="$FZF_CTRL_T_OPTS --prompt=\'$(prompt_pwd)/\'" fzf-file-widget'
    # use ctrl+h for history search instead of default ctrl+r
    bind --erase \cr
    bind \ch fzf-history-widget
    # use alt+d for directory search instead of default alt+c
    bind --erase \ec
    bind \ed 'FZF_ALT_C_OPTS="$FZF_ALT_C_OPTS --prompt=\'$(prompt_pwd)/\'" fzf-cd-widget'

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
    abbr --add --global ls 'ls --color=never --classify --hyperlink=auto'
    # include hidden files
    abbr --add --global la 'ls --color=never --classify --almost-all --hyperlink=auto'
    # use the long format and a more human-readable format for sizes e.g. 25M
    abbr --add --global ll 'ls --color=never --classify -l --human-readable --hyperlink=auto'
    # combination of the the two above
    abbr --add --global lal 'ls --color=never --classify --almost-all -l --human-readable --hyperlink=auto'

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
    abbr --add --global au 'sudo apt update'
    abbr --add --global as apt-show
    abbr --add --global ap 'apt policy'
    abbr --add --global alu 'apt list --upgradeable'
    abbr --add --global ap 'sudo apt purge'
    abbr --add --global fai 'fzf-apt-install-widget'
    abbr --add --global far 'fzf-apt-remove-widget'

    # asdf version manager
    set --global --export ASDF_VIM_CONFIG \
        "--enable-fail-if-missing \
        --with-tlib=ncurses \
        --with-features=huge \
        --with-compiledby=asdf \
        --enable-multibyte \
        --enable-cscope \
        --enable-terminal \
        --enable-perlinterp \
        --enable-rubyinterp \
        --enable-python3interp \
        --enable-luainterp \
        --with-x \
        --enable-gui=no"
    # Part of asdf initialization is adding shims. This means that if this config
    # gets reloaded, then asdf will add its shims again. This could be an issue if
    # this config gets reloaded while you're inside a python virtual environment
    # since the asdf shims will be placed before the virtual environment shims in the PATH.
    # To get around this, we make sure asdf is only initialized once by setting
    # a variable after init and only initializing asdf if that variable doesn't exist.
    if not set --query ASDF_INITIALIZED
        source ~/.asdf/asdf.fish
        # Set this variable so we can tell if asdf has been initialized.
        # It purposely isn't exported so that sub shells (e.g. tmux shells)
        # don't inherit this value. This way sub shells perform initialization as well which is
        # necessary since asdf loads functions as part of initialization and functions
        # don't get inherited by sub shells.
        set --global ASDF_INITIALIZED
    end

    # python
    # Don't add the name of the virtual environment to my prompt. This way, I can add it myself
    # using the same formatting as the rest of my prompt.
    set --global --export VIRTUAL_ENV_DISABLE_PROMPT 1

    # ripgrep
    set --global --export RIPGREP_CONFIG_PATH "$HOME/.ripgreprc"

    # zoxide
    set --global --export _ZO_FZF_OPTS "$FZF_DEFAULT_OPTS --preview 'ls --classify -C {2}' --keep-right --bind='change:first'"
    zoxide init fish | source

    # direnv
    direnv hook fish | source
    # toggle activation/deactivation messages
    abbr --add --global dirlog \
        'set --query DIRENV_LOG_FORMAT; and set --erase DIRENV_LOG_FORMAT; or set --global --export DIRENV_LOG_FORMAT'
    # disable activation/deactivation messages
    set --global --export DIRENV_LOG_FORMAT

    # kitty shell integration
    if set -q KITTY_INSTALLATION_DIR
        source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
        set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"
    end

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
        if set --query IN_TMUX
            return
        end

        type --query figlet
        and figlet -ktc -f slant Fish Shell v$version
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
