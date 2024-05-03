if not status is-interactive
    exit
end

abbr --add --global g git
set --global --export PAGER less
abbr --add --global x 'chmod +x'
abbr --add --global du 'du --dereference --human-readable --summarize --apparent-size'
if test (uname) = Linux
    abbr --add --global initramfs-reload 'sudo update-initramfs -u -k all'
    abbr --add --global logout-all 'sudo killall -u $USER'
    abbr --add --global icon-reload 'sudo update-icon-caches /usr/share/icons/* ~/.local/share/icons/*'
    # reload the database used to search for applications
    abbr --add --global desktop-entry-reload 'sudo update-desktop-database; update-desktop-database ~/.local/share/applications'
    abbr --add --global ruhroh 'sudo truncate -s 0 /var/log/syslog'
    abbr --add --global font-reload 'fc-cache -vr'
    if type --query flatpak
        and flatpak list --app | grep -q 'org.wezfurlong.wezterm'
        alias wezterm 'flatpak run org.wezfurlong.wezterm'
    end
    abbr --add --global open xdg-open
    abbr --add --position anywhere --global pbpaste fish_clipboard_paste
    # autocomplete doesn't work unless "put" is used, even though just 'trash'
    # is an alias for 'trash put'
    abbr --add --position anywhere --global trash 'trash put'
end

# timg
function timg --wraps timg
    set pixelation_options
    # TODO: timg doesn't use sixel for TMUX so I'll do it here. I should open an
    # issue to let them know it supports sixel now
    if set --query TMUX
        set pixelation_options -p sixel
    end

    command timg --center $pixelation_options $argv
end

# man
# Per the man manpage, spaces in $MANOPT must be escaped with a backslash
set --global --export MANOPT --no-hyphenation
# There's an environment variable you can set to change man's pager (MANPAGER),
# but I'm not using it because I only want to change the pager in interactive
# mode. I'm also not using an alias because that wouldn't work with `command man
# ...`.
abbr --add --global --position anywhere -- man 'man -P "page -t man"'

# Set preferred editor.
#
# BACKGROUND: Historically, EDITOR referred to a line editor (e.g. ed) and
# VISUAL referred to a fullscreen editor (e.g. vi), the latter requiring a more
# advanced terminal. Programs could then attempt to run the VISUAL editor, and
# if it wasn't supported, fall back to EDITOR. However, since practically all
# terminals today support a fullscreen (VISUAL) editor, this distinction is no
# longer necessary.
#
# Since some programs just use the value in EDITOR without checking VISUAL, and
# vice-versa, I set both to the same editor.  For more info:
# https://unix.stackexchange.com/questions/4859/visual-vs-editor-what-s-the-difference/302391#302391
set --global --export VISUAL (command -v edit)
set --global --export EDITOR $VISUAL
abbr --add --global -- vim nvim

# Change the color grep uses for highlighting matches to magenta
set --global --export GREP_COLORS 'ms=00;35'

# ls
# use the long format
abbr --add --position anywhere --global ll 'ls -l'
# Add colors for files types that aren't already given an icon by `ls
# --classify` e.g. broken symlinks.
#
# TODO: I added color for some types that are already given icons by `ls
# --classify`. The colors let me distinguish between the file name and the icon
# added by `--classify`. I'll remove these colors when `lsd` allows for more
# configurable icons. see my `lsd` config for details.
#
# File types:
# [bd]="block device"
# [ca]="file with capability"
# [cd]="character device"
# [di]="directory"
# [do]="door"
# [ex]="executable file"
# [fi]="regular file"
# [ln]="symbolic link"
# [mh]="multi-hardlink"
# [mi]="missing file"
# [no]="normal non-filename text"
# [or]="orphan symlink"
# [ow]="other-writable directory"
# [pi]="named pipe, AKA FIFO"
# [rs]="reset to no color"
# [sg]="set-group-ID"
# [so]="socket"
# [st]="sticky directory"
# [su]="set-user-ID"
# [tw]="sticky and other-writable directory"
# From: https://askubuntu.com/a/884513/1497983
set --global --export LS_COLORS 'di=0:ln=35:so=35:pi=35:ex=35:bd=35:cd=35:su=35:sg=35:tw=35:ow=35:or=31:mi=31:no=37:*=37'

# cd
abbr --add --global -- - 'cd -'

# python
# Don't add the name of the virtual environment to my prompt. This way, I can
# add it myself using the same formatting as the rest of my prompt.
set --global --export VIRTUAL_ENV_DISABLE_PROMPT 1
function python --wraps python
    # Check if python is being run interactively
    if test (count $argv) -eq 0
        or contains -- -i $argv
        # Check if python has the ipython package installed
        #
        # If I pipe the output of python to grep, python will raise a
        # BrokenPipeError. To avoid this, I use echo to pipe the output.
        if echo (command python -m pip list) | grep -q ipython
            python -m IPython
            return
        end
    end
    command python $argv
end

# zoxide
set --global --export _ZO_FZF_OPTS "$FZF_DEFAULT_OPTS --preview 'lsd --color always --hyperlink always {2}' --keep-right --tiebreak index"
# This needs to run after the zoxide.fish config file so I run it when the
# fish_prompt event fires.
function __create_cd_function --on-event fish_prompt
    # I only want this to run once so delete the function.
    functions -e (status current-function)

    function cd --wraps cd
        # zoxide does not support the '--' argument
        if set index (contains --index -- '--' $argv)
            set --erase argv[$index]
        end
        __zoxide_z $argv
    end
end
function cdh --wraps=__zoxide_zi --description 'cd history'
    __zoxide_zi $argv
end

# direnv
set --global --export DIRENV_LOG_FORMAT (set_color brblack)'[direnv] %s'(set_color normal)
set -g direnv_fish_mode disable_arrow # trigger direnv at prompt only

# watch
abbr --add --global watch 'watch --no-title --differences --interval 0.5'

# vscode
# Clearing the $TMUX variable so that the integrated terminal in vscode won't
# think it's in TMUX.  Clearing SHELL because my config for the OS default shell
# only launches fish if the current shell isn't fish.
abbr --add --global code 'TMUX= SHELL= code'

# ulimit
#
# Increase maxixmum number of open file descriptors that a single process can
# have. This applies to the current process and its descendents.
ulimit -Sn 10000

# comma
function , --wraps ,
    # The `--with-nth` to remove the '.out' extension from the entries.
    FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --separator '' --height ~100% --margin 0,2,0,2 --preview-window 7 --preview 'nix-info {}' --delimiter '.' --with-nth '..-5'" COMMA_PICKER=fzf command , $argv
end

# touch
function touchx
    set filename "$argv"
    touch "$filename"
    chmod +x "$filename"
end
function touchp --description 'Create file and make parent directories' --argument-names filepath
    set -l parent_folder (dirname $filepath)
    mkdir -p $parent_folder
    touch $filepath
end

# Launch a program and detach from it. Meaning it will be disowned and its
# output will be suppressed
#
# TODO: Have it wrap sudo so it autocompletes program names.  I should write my
# own completion script though since this will also autocomplete sudo flags.
function detach --wraps sudo
    # Redirecting the i/o files on the command itself still resulted in some
    # output being sent to the terminal, but putting the command in a block and
    # redirecting the i/o files of the block does the trick.
    begin
        $argv & disown
    end >/dev/null 2>/dev/null </dev/null
end

function tunnel --description 'Connect my cloudflare tunnel to the specified port on localhost' --argument-names port
    if test (count $argv) -eq 0
        set function_name (status current-function)
        echo -s \
            (set_color red) \
            "ERROR: You need to specify a port, e.g. '$function_name 8000'" >/dev/stderr
        return 1
    end
    cloudflared tunnel run --url "http://localhost:$port"
end

function rust --description 'run the given rust source file' --wraps rustc
    if test (count $argv) -eq 0
        echo -s \
            (set_color red) \
            'ERROR: You must provide at least one argument, the source file to run' >/dev/stderr
        return 1
    end

    set source_file $argv[-1]
    set executable_name (basename $source_file .rs)
    rustc $argv
    and begin
        ./$executable_name
        rm $executable_name
    end
end

function dig --wraps doggo
    doggo --color=false $argv
end

function df --wraps duf
    duf -theme ansi $argv
end

function ping --wraps gping
    gping $argv
end

function ls --wraps lsd
    lsd $argv
end

# Wrapping watch since viddy doesn't have autocomplete
function watch --wraps watch
    viddy --pty $argv
end

function sh --wraps yash
    if type --query yash
        yash $argv
    else
        command sh $argv
    end
end

abbr --add --global chase 'chase --verbose'

# broot
function dui --wraps broot --description 'Check disk usage interactively'
    br -w $argv
end
abbr --add --global tree broot

# lesspipe
#
# TODO: lesspipe requires this to be set to enable syntax highlighting. I should
# open an issue to have it read lesskey
set --global --export LESS -R

# diffoscope
function diff-html
    set temp (mktemp --suffix .html)
    diffoscope \
        --html "$temp" \
        --jquery 'https://cdnjs.cloudflare.com/ajax/libs/jquery/3.7.1/jquery.min.js' \
        $argv
    open "$temp"
end
function diff
    if isatty 1
        diffoscope --text-color always $argv | page
    else
        diffoscope --text-color always $argv
    end
end
