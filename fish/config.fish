if not status is-interactive
    exit
end

abbr --add --global trash trash-put
abbr --add --global t-sys sysz
abbr --add --global g git
abbr --add --global touchp touch-and-make-parent-dirs
set --global --export PAGER less
abbr --add --global ruhroh 'sudo truncate -s 0 /var/log/syslog'
abbr --add --global x 'chmod +x'
abbr --add --global r-initramfs 'sudo update-initramfs -u -k all'
abbr --add --global logout-all 'sudo killall -u $USER'
abbr --add --global r-icons 'sudo update-icon-caches /usr/share/icons/* ~/.local/share/icons/*'
abbr --add --global du 'du -sh'

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
abbr --add --global r 'reload-fish'
# Don't print a greeting when a new interactive fish shell is started
set --global --export fish_greeting ''
# use ctrl+z to resume the most recently suspended job
function _resume_job
    if not jobs --query
        return
    end

    set job_count (jobs | wc -l)

    if test "$job_count" -eq 1
        fg 1>/dev/null 2>&1

        # this should be done whenever a binding produces output (see: man bind)
        commandline -f repaint

        return
    end

    set entries
    for job_pid in (jobs --pid)
        set job_command (ps -o command= --pid "$job_pid")
        set --append entries "$job_pid:$job_command"
    end

    set choice \
        ( \
            printf '%s\n' $entries | \
            fzf  \
            --delimiter ':' \
            --with-nth '2..' \
            --no-preview \
            --height 30% \
        )
    and begin
        set tokens (string split ':' "$choice")
        set pid $tokens[1]
        fg "$pid" 1>/dev/null 2>&1
    end

    # this should be done whenever a binding produces output (see: man bind)
    commandline -f repaint
end
bind-no-focus \cz '_resume_job'
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
            # remove duplicates
            | sort --unique \
            | fzf \
            --preview 'echo {2}' \
            --delimiter \t \
            --preview-window '50%' \
            --height 45% \
            --no-header \
            --bind 'backward-eof:abort' \
            --select-1 \
            --prompt "$(commandline --current-token)" \
            --exit-0 \
            --no-hscroll \
            --color 'gutter:-1,prompt:6' \
            --tiebreak=begin,chunk \
        )
    and begin
        set entry "$(string split -f1 -- \t $choice)"

        set space ' '
        # Only add a space after the entry if it isn't an abbreviation.
        #
        # TODO: This assumes that an abbreviation can only be expanded if it's the first token in the commandline.
        # However, with the flag '--position anywhere', abbreviations can be expanded anywhere in the commandline so
        # I should check for that flag.
        #
        # TODO: Need to account for when the directory starts with tilde, gotta expand it
        #
        # We determine if the entry will be the first token by checking for an empty commandline.
        # We trim spaces because spaces don't count as tokens.
        set trimmed_commandline (string trim "$(commandline)")
        if abbr --query -- "$entry"
        and test -z "$trimmed_commandline"
            set space ''
        else if test -d "$entry"
        and printf "$entry" | grep -q -E '\/$'
            set space ''
        else if test -d "$PWD/$entry"
        and printf "$entry" | grep -q -E '\/$'
            set space ''
        end

        commandline --replace --current-token -- "$entry$space"
    end

    commandline -f repaint
end
function _fzf_complete_helper
    if commandline --paging-mode
        commandline -f forward-char
        return
    end

    if not type --query fzf
        commandline -f complete
    else
        _fzf_complete
    end
end
bind-no-focus -k btab _fzf_complete_helper
# Save command to history before executing it. This way long running commands, like ssh or watch, will show up in
# the history immediately.
function __save_history --on-event fish_preexec
    history --save
end
# Taken from fish's default keybind for ctrl+l.
function _clear_screen
    echo -n (clear | string replace \e\[3J "")
end
bind \ec _clear_screen 'commandline -f repaint'

# sudo
abbr --add --global s 'sudo --preserve-env=PATH'
abbr --add --global sudo 'sudo --preserve-env=PATH'

# ps
abbr --add --global fp fzf-process-widget

# timg
# timg doesn't detect Wezterm so I'll do it here
alias timg 'env | grep -q WEZTERM && command timg -p kitty || command timg'

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
set --global --export VISUAL (command -v nvim)
set --global --export EDITOR $VISUAL

# Change the color grep uses for highlighting matches to magenta
set --global --export GREP_COLORS 'ms=00;35'

# Sets the cursor shape to a blinking bar
echo -ne '\033[5 q'

# ls
# use the long format
abbr --add --global ll 'ls -l'
# broken symlinks or missing files (files that a symlink references, but don't exist) are colored red, everything
# else is the normal color
set --global --export LS_COLORS 'di=0:ln=0:so=0:pi=0:ex=0:bd=0:cd=0:su=0:sg=0:tw=0:ow=0:or=31:mi=31:no=37:*=37'

# cd
abbr --add --global -- - 'cd -'

# tmux
abbr --add --global ta tmux attach-session
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

# nix
abbr --add --global 'nr' 'nix repl --file ~/.config/nix/repl-startup.nix'

# python
# Don't add the name of the virtual environment to my prompt. This way, I can add it myself
# using the same formatting as the rest of my prompt.
set --global --export VIRTUAL_ENV_DISABLE_PROMPT 1

# ripgrep
set --global --export RIPGREP_CONFIG_PATH "$HOME/.ripgreprc"

# zoxide
set --global --export _ZO_FZF_OPTS "$FZF_DEFAULT_OPTS --preview 'type --query lsd; and lsd {2}; or ls {2}' --keep-right --bind='change:first' --height 40% --preview-window '50%'"
if type --query zoxide
    zoxide init --cmd cd fish | source

    # overwrite the cd function that zoxide creates to handle the '--' argument
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
set --global --export DIRENV_LOG_FORMAT (set_color brwhite)'[direnv] %s'(set_color normal)

# fish-abbreviation-tips
set --global --export ABBR_TIPS_PROMPT "\n$(set_color --reverse --bold blue) TIP $(set_color normal) If you type $(set_color blue)'{{ .abbr }}'$(set_color normal) it will expand to $(set_color blue)'{{ .cmd }}'$(set_color normal)"
# history-search-backward wrapper for the fish-abbreviation-tips plugin.
# This way, I won't get reminded about an abbreviation when executing a command
# from the history
function __abbr_tips_history_backward
    set -g __abbr_tips_used 1
    commandline -f history-search-backward
end
bind \e\[A __abbr_tips_history_backward
# If the commandline contains the most recent item in the history, we assume that moving forward in the history
# will exit the history. In this case, reenable abbreviation tips.
function __abbr_tips_history_forward
    set last_history_item (history --reverse | tail -1)
    if test "$last_history_item" = "$(commandline)"
        set -g __abbr_tips_used 0
    end

    commandline -f history-search-forward
end
bind \e\[B __abbr_tips_history_forward
# This way, I won't get reminded about an abbreviation when executing the autosuggested command
function __abbr_tips_forward_char
    set -g __abbr_tips_used 1
    commandline -f forward-char
end
bind \e\[C __abbr_tips_forward_char

# pipr
abbr --add --global pipr 'pipr --no-isolation'
bind-no-focus \cp pipr-widget

# watch
abbr --add --global watch 'watch --no-title --differences --interval 0.5'

# vscode
# Also clearing the $TMUX variable so that the integrated terminal in vscode won't think it's in TMUX.
abbr --add --global code 'TMUX= code'

# fonts
# For debugging. Launches a window displaying the specified character in the specified font. Also, prints a ton of
# information to the console. The last font family listed in that output is probably the family being used to
# render the specified character.
abbr --add --global font-debug 'DISPLAY=:0 FC_DEBUG=4 pango-view --font=monospace -t ☺ | grep family:'
abbr --add --global reload-fonts 'fc-cache -vr'

# ncdu
abbr --add --global ncdu 'ncdu --color off'

# ulimit
#
# Increase maxixmum number of open file descriptors that a single process can have. This applies to the current
# process and its descendents.
ulimit -Sn 10000

# Initialize fish-abbreviation-tips. The plugin only runs init once when the plugin is installed so if I add new
# abbreviations after that, the plugin won't give tips for them. This should be towards the end of this file so that
# any abbreviations created in this file get loaded into fish-abbreviation-tips. I run it in the background so it
# doesn't impact load time.
#
# UPDATE: Because I install plugins through Nix Home Manager, the init is never run so I need this even more.
# See the declaration of this plugin in HM for more info.
#
# TODO: Fish doesn't support running functions in the background so I run it in a child shell instead. Since my
# abbreviations only get defined in an interactive shell, I load them into the child shell using --init-command.
# issue: https://github.com/fish-shell/fish-shell/issues/238
fish --init-command "source $(abbr | psub)" --command '__abbr_tips_install' & disown

# any-nix-shell
if type --query any-nix-shell
    any-nix-shell fish | source
end

# comma
function , --wraps ,
    # The `--with-nth` to remove the '.out' extension from the entries.
    FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --height 30% --no-preview --no-header --delimiter '.' --with-nth '..-5'" COMMA_PICKER=fzf command , $argv
end

# wezterm
alias wezterm 'flatpak run org.wezfurlong.wezterm'

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
