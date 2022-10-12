if not status is-interactive
    exit
end

abbr --add --global trash trash-put
abbr --add --global t-sys sysz
abbr --add --global r-asdf 'asdf reshim'
abbr --add --global r-kitty reload-kitty
abbr --add --global g git
abbr --add --global touchp touch-and-make-parent-dirs
set --global --export PAGER less
abbr --add --global ruhroh 'sudo truncate -s 0 /var/log/syslog'

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
set --global --export fish_color_comment brwhite
set --global --export fish_color_match
set --global --export fish_color_search_match --background=brblack
# TODO: I want to remove the default bolding, but currently only the background is configurable.
# Issue: https://github.com/fish-shell/fish-shell/issues/2442
set --global --export fish_pager_color_selected_background --background=brblack
set --global --export fish_color_operator
set --global --export fish_color_escape
set --global --export fish_color_cwd
set --global --export fish_color_autosuggestion brwhite
set --global --export fish_color_user
set --global --export fish_color_host
set --global --export fish_pager_color_prefix cyan
set --global --export fish_pager_color_completion
set --global --export fish_pager_color_description
set --global --export fish_pager_color_progress --background=brblack normal
set --global --export fish_pager_color_secondary
set --global --export fish_color_cancel black
set --global --export fish_color_valid_path
# reload this config file
abbr --add --global r 'exec fish'
# Don't print a greeting when a new interactive fish shell is started
set --global --export fish_greeting ''
# use ctrl+z to resume the most recently suspended job
bind \cz 'jobs --query; and fg'
# use ctrl+right-arrow to accept the next suggested word
bind \e\[1\;3C forward-word
# use ctrl+b to jump to beginning of line
bind \cb beginning-of-line
# ctrl+r to refresh terminal, shell, and screen
bind \cr 'reset && exec fish && clear'
# search variables
abbr --add --global fv 'FZF_DEFAULT_COMMAND="set --names" fzf --preview "set --show {}"'
# set terminal title
echo -ne "\033]0;fish\007"
# Use shift+tab to select an autocomplete entry with fzf
function _fzf_complete
    set choice \
        ( \
            complete --escape --do-complete (commandline --cut-at-cursor) \
            | if type --query python
                # Remove duplicates
                # The [:-1] is to remove the newline.
                python -c "import fileinput; lines = list(line[:-1].split('\t') for line in fileinput.input()); items = {line[0]: line[0] + '\t(' + line[1].rstrip() + ')' if len(line) == 2 else line[0] for line in lines}; print('\n'.join(items.values()));"
            else
                cat
            end \
            | fzf \
            --preview 'string sub --start 2 --end -1 -- {2}' \
            --delimiter \t \
            --preview-window '50%' \
            --height 30% \
            --no-header \
            --bind 'backward-eof:abort' \
            --select-1 \
            --exit-0 \
            --query (commandline --current-token --cut-at-cursor) \
            --no-hscroll \
        )
    and begin
        set entry (string split -f1 -- \t $choice)
        commandline --replace --current-token -- $entry
    end

    commandline -f repaint
end
function _fzf_complete_or_last_entry
    if commandline --paging-mode
        commandline -f backward-char
    else
        _fzf_complete
    end
end
# TODO: If you press shift+tab when the first entry is selected, it doesn't unselect it wraps around
bind -k btab _fzf_complete_or_last_entry
# Save command to history before executing it. This way long running commands, like ssh or watch, will show up in
# the history immediately.
function __save_history --on-event fish_preexec
    history --save
end

# sudo
abbr --add --global s sudo

# cloudflared
abbr --add --global tunnel cloudflared-tunnel

# ps
abbr --add --global fp fzf-process-widget

# man
# NOTE: Per the man manpage, spaces in $MANOPT must be escaped with a backslash
set --global --export MANOPT '--no-hyphenation'
abbr --add --global fm fzf-man-widget

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
set --global --export VISUAL (which nvim)
set --global --export EDITOR $VISUAL

# Change the color grep uses for highlighting matches to magenta
set --global --export GREP_COLORS 'ms=00;35'

# Sets the cursor shape to a blinking bar
echo -ne '\033[5 q'

# ls
abbr --add --global ls 'ls'
# include hidden files
abbr --add --global la 'ls --almost-all'
# use the long format
abbr --add --global ll 'ls -l'
# combination of the two above
abbr --add --global lal 'ls --almost-all -l'
# broken symlinks or missing files (files that a symlink references, but don't exist) are colored red, everything
# else is the normal color
set --global --export LS_COLORS 'di=0:ln=0:so=0:pi=0:ex=0:bd=0:cd=0:su=0:sg=0:tw=0:ow=0:or=31:mi=31:no=37:*=37'

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
abbr --add --global bo 'brew outdated --fetch-HEAD'
set --global --export HOMEBREW_NO_INSTALL_UPGRADE 1
set --global --export HOMEBREW_NO_INSTALL_CLEANUP 1
set --global --export HOMEBREW_BUNDLE_NO_LOCK 1
set --global --export HOMEBREW_BUNDLE_FILE '~/.config/brewfile/Brewfile'

# asdf version manager
set _asdf_init_script "$(brew --prefix asdf)/libexec/asdf.fish"
test -e $_asdf_init_script
and source $_asdf_init_script

# fisher
if not type --query fisher
    echo -s (set_color blue) "'fisher' was not found, installing now..."
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source

    # If installing fisher is successful, install the plugins from fish_plugins if the file exists.
    # If it doesn't, just install the fisher plugin so it can manage itself.
    and begin
        set fish_plugins_path "$__fish_config_dir/fish_plugins"
        if test -e $fish_plugins_path
            echo -s (set_color blue) "fisher: Installing plugins from 'fish_plugins'"
            fisher update
        else
            fisher install jorgebucaran/fisher
        end
    end
end

# python
# Don't add the name of the virtual environment to my prompt. This way, I can add it myself
# using the same formatting as the rest of my prompt.
set --global --export VIRTUAL_ENV_DISABLE_PROMPT 1

# ripgrep
set --global --export RIPGREP_CONFIG_PATH "$HOME/.ripgreprc"

# zoxide
set --global --export _ZO_FZF_OPTS "$FZF_DEFAULT_OPTS --preview 'type --query lsd; and lsd --icon=always {2}; or ls {2}' --keep-right --bind='change:first' --height 40% --preview-window '50%'"
if type --query zoxide
    zoxide init --no-cmd fish | source

    function cd --wraps cd
        # zoxide does not support the '--' argument
        if set index (contains --index -- '--' $argv)
            set --erase argv[$index]
        end
        __zoxide_z $argv
    end
end

# direnv
if type --query direnv
    direnv hook fish | source
end
# toggle activation/deactivation messages
set --global --export DIRENV_LOG_FORMAT "$(set_color brwhite)%s$(set_color normal)"
abbr --add --global dirlog \
    'set --query DIRENV_LOG_FORMAT; and set --erase DIRENV_LOG_FORMAT; or set --global --export DIRENV_LOG_FORMAT "$(set_color brwhite)%s$(set_color normal)"'

# fish-abbreviation-tips
set --global --export ABBR_TIPS_PROMPT "\n[$(set_color yellow)tip$(set_color normal)] If you type $(set_color yellow)'{{ .abbr }}'$(set_color normal) it will expand to $(set_color yellow)'{{ .cmd }}'$(set_color normal)"
# history-search-backward wrapper for the fish-abbreviation-tips plugin.
# This way, I won't get reminded about an abbreviation when executing a command
# from the history
function __abbr_tips_history_backward
    set -g __abbr_tips_used 1
    commandline -f history-search-backward
end
bind \e\[A __abbr_tips_history_backward
# This way, I won't get reminded about an abbreviation when executing the autosuggested command
function __abbr_tips_forward_char
    set -g __abbr_tips_used 1
    commandline -f forward-char
end
bind \e\[C __abbr_tips_forward_char

# pipr
abbr --add --global pipr 'pipr --no-isolation'
bind \cp pipr-widget

# pipenv
if type --query pipenv
    # enable autocomplete
    if set --query XDG_CONFIG_HOME
        set xdg_config_home $XDG_CONFIG_HOME
    else
        set xdg_config_home "$HOME/.config"
    end
    set fish_config_path "$xdg_config_home/fish/conf.d"
    set pipenv_autocomplete "$fish_config_path/pipenv-autocomplete.fish"
    if not test -f $pipenv_autocomplete
        env _PIPENV_COMPLETE=fish_source pipenv > $pipenv_autocomplete
        source $pipenv_autocomplete
    end
end

# watch
abbr --add --global watch 'watch --no-title --differences --interval 0.5'

# vscode
# Make vscode run natively in Wayland, as opposed to using xwayland. This way the font won't be blurry on HiDPI screens.
abbr --add --global code 'code --enable-features=UseOzonePlatform --ozone-platform=wayland'

# fonts
# Setting this to 1 means I can use nerdfont glyphs
set --global --export NERDFONT_ENABLE '1'
# For debugging. Launches a window displaying the specified character in the specified font. Also, prints a ton of
# information to the console. The last font family listed in that output is probably the family being used to
# render the specified character.
abbr --add --global font-debug 'DISPLAY=:0 FC_DEBUG=4 pango-view --font=monospace -t ☺ | grep family:'

# Print banner
if not set --query BANNER_WAS_PRINTED
    set banner Fish Shell v(string split ' ' (fish --version) | tail -n 1)

    set figlet_font "$HOME/.local/share/figlet/smblock.tlf"
    if type --query figlet
    and test -f $figlet_font
        figlet -W -f $figlet_font $banner
    else
        echo $banner
    end

    set --global --export BANNER_WAS_PRINTED
end

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

    set accent (set_color cyan)
    set normal (set_color normal)
    read --prompt "echo -n -s 'Welcome back $USER, would you like to connect to tmux? (' '$accent' 'y' '$normal' '/' '$accent' 'n' '$normal' '): ';" --nchars 1 response
    if test $response = y
        tmux-attach-or-create
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
