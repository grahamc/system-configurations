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
#
# WARNING: Be sure that none of the commands in this block generate any output to stdout or stderr
# (e.g. 'echo thisisoutput'). Since this block gets run when fish is running a script, the output
# could break a script that expects certain content, or no content, in stdout or stderr.
# For an example of how output could break ssh/scp/rsync, see the following link:
# https://fishshell.com/docs/current/faq.html#why-won-t-ssh-scp-rsync-connect-properly-when-fish-is-my-login-shell
if not status is-interactive
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

    abbr --add --global trash trash-put
    abbr --add --global t-sys sysz
    abbr --add --global r-asdf 'asdf reshim'
    abbr --add --global r-kitty reload-kitty
    abbr --add --global g git

    # reload the database used to search for applications
    abbr --add --global r-desktop-entries 'sudo update-desktop-database; update-desktop-database ~/.local/share/applications'

    # fish
    set --global --export fish_color_normal
    set --global --export fish_color_command
    set --global --export fish_color_quote
    set --global --export fish_color_redirection
    set --global --export fish_color_end
    set --global --export fish_color_error red
    set --global --export fish_color_param
    set --global --export fish_color_comment brblack
    set --global --export fish_color_match
    set --global --export fish_color_search_match --background=black
    set --global --export fish_color_operator
    set --global --export fish_color_escape
    set --global --export fish_color_cwd
    set --global --export fish_color_autosuggestion blue
    set --global --export fish_color_user
    set --global --export fish_color_host
    set --global --export fish_pager_color_prefix
    set --global --export fish_pager_color_completion
    set --global --export fish_pager_color_description
    set --global --export fish_pager_color_progress --reverse --bold
    set --global --export fish_pager_color_secondary
    # reload this config file
    abbr --add --global r 'source ~/.config/fish/config.fish'
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
    # transient prompt
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
    # TODO: This disables fish's default window resize (SIGWINCH) handler and defines a new one that clears the screen
    # after reloading the prompt. This covers up an issue between the terminal's linewrapping
    # and fish's prompt reloading that results in a stray line of the old prompt being left on the screen.
    #
    # issue filed with VTE: https://gitlab.gnome.org/GNOME/vte/-/issues/2294
    # issue filed with fish: https://github.com/fish-shell/fish-shell/issues/2320
    set --global --export fish_handle_reflow 0
    function _handle_resize --on-signal SIGWINCH
        commandline -f repaint >/dev/null 2>/dev/null
        # Clear the screen. Taken from the default ctrl+l keybinding for fish
        echo -n (clear | string replace \e\[3J "")
    end
    # separate interactive commands with a line
    function _print_command_separator --on-event fish_postexec
        echo -n -e -s (set_color black) (string repeat -n $COLUMNS \u2015) "\n" (set_color normal)
    end

    # cloudflared
    abbr --add --global tunnel cloudflared-tunnel

    # fzf
    bind \cg fzf-grep-widget
    set --global --export FZF_DEFAULT_OPTS "
        --multi
        --cycle
        --bind tab:down,shift-tab:up,alt-enter:toggle,alt-down:last,alt-up:first,backward-eof:abort,change:first
        --layout=reverse
        --header-first
        --info=hidden
        --color='bg+:-1,fg+:cyan,info:black,gutter:bright-black,pointer:cyan:regular,prompt:bright-black:regular,border:black,query:-1:regular,marker:cyan:regular,header:magenta,spinner:magenta,hl:cyan,hl+:cyan'
        --margin=7%
        --height 100%
        --prompt='❯ '
        --pointer='❯'
        --marker='❯'
        --preview-window=wrap,60%
        --keep-right"
    set --global --export FZF_ALT_C_COMMAND "rg --files --null | xargs -0 dirname | sort -u"
    set --global --export FZF_ALT_C_OPTS "--preview 'ls --classify {}' --prompt='directories: '"
    set --global --export FZF_CTRL_T_COMMAND ''
    set --global --export FZF_CTRL_T_OPTS '--preview "head -100 {}" --prompt="files: "'
    set --global --export FZF_CTRL_R_OPTS '--prompt="history: "'
    # use ctrl+f for file search instead of default ctrl+t
    bind --erase \ct
    bind \cf fzf-file-widget

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

    # Set default less options.
    # 'R' - process color (ANSI) and hyperlink (OSC 8) escape sequences.
    # 'i' - ignore case, except when the search term contains a capital letter.
    # 'F' - If the content can fit in one terminal window, print it and exit.
    set --global --export LESS -RiF

    # Change the color grep uses for highlighting matches to yellow
    set --global --export GREP_COLORS 'ms=01;33'

    # Sets the cursor shape to a blinking bar
    echo -ne '\033[5 q'

    # ls
    abbr --add --global ls 'ls --color=never --classify'
    # include hidden files
    abbr --add --global la 'ls --color=never --classify --almost-all'
    # use the long format and a more human-readable format for sizes e.g. 25M
    abbr --add --global ll 'ls --color=never --classify -l --human-readable'
    # combination of the the two above
    abbr --add --global lal 'ls --color=never --classify --almost-all -l --human-readable'

    # cd
    abbr --add --global -- - 'cd -'

    # tmux
    abbr --add --global ta tmux-attach-or-create
    abbr --add --global r-tmux 'tmux source ~/.tmux.conf && tmux display-message "Reloaded TMUX..."'
    abbr --add --global r-tmux-plugins "$HOME/.tmux/plugins/tpm/bindings/install_plugins"
    abbr --add --global r-tmux-server reload-tmux-server

    # apt
    abbr --add --global sai 'sudo apt install'
    abbr --add --global sar 'sudo apt remove'
    abbr --add --global saar 'sudo apt autoremove'
    abbr --add --global sau 'sudo apt update'
    abbr --add --global as apt-show
    abbr --add --global ap 'apt policy'
    abbr --add --global alu 'apt list --upgradeable'

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
    export VIRTUAL_ENV_DISABLE_PROMPT=1

    # ripgrep
    export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

    # zoxide
    zoxide init fish | source

    # direnv
    direnv hook fish | source
    # toggle activation/deactivation messages
    abbr --add --global dirlog \
        'set --query DIRENV_LOG_FORMAT; and set --erase DIRENV_LOG_FORMAT; or set --global --export DIRENV_LOG_FORMAT'
    # disable activation/deactivation messages
    set --global --export DIRENV_LOG_FORMAT

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

        echo 'Would you like to connect to tmux? (y/n):'
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
