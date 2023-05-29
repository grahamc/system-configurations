if not status is-interactive
    exit
end

abbr --add --global g git
set --global --export PAGER less
abbr --add --global ruhroh 'sudo truncate -s 0 /var/log/syslog'
abbr --add --global x 'chmod +x'
abbr --add --global r-initramfs 'sudo update-initramfs -u -k all'
abbr --add --global logout-all 'sudo killall -u $USER'
abbr --add --global r-icons 'sudo update-icon-caches /usr/share/icons/* ~/.local/share/icons/*'
abbr --add --global du 'du -shL'
# reload the database used to search for applications
abbr --add --global r-desktop-entries 'sudo update-desktop-database; update-desktop-database ~/.local/share/applications'
# Set the terminal's color capability to 256 colors if it isn't already. 
if not string match --regex --quiet -- '256' $TERM
    set --global --export TERM xterm-256color
end

# sudo
abbr --add --global s 'sudo --preserve-env=PATH'
abbr --add --global sudo 'sudo --preserve-env=PATH'

# timg
function timg --wraps timg
    set pixelation_options
    # timg doesn't detect Wezterm or TMUX so I'll do it here
    if set --query TMUX
        set pixelation_options '-p' 'quarter'
    else if test "$TERM_PROGRAM" = 'WezTerm'
        set pixelation_options '-p' 'kitty'
    end

    command timg --center $pixelation_options $argv
end

# man
# NOTE: Per the man manpage, spaces in $MANOPT must be escaped with a backslash
set --global --export MANOPT '--no-hyphenation'

# neovim
#
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
function vim --wraps nvim
    nvim $argv
end

# Change the color grep uses for highlighting matches to magenta
set --global --export GREP_COLORS 'ms=00;35'

# ls
# use the long format
abbr --add --global ll 'ls -l'
# broken symlinks or missing files (files that a symlink references, but don't exist) are colored red, everything
# else is the normal color
set --global --export LS_COLORS 'di=0:ln=0:so=0:pi=0:ex=0:bd=0:cd=0:su=0:sg=0:tw=0:ow=0:or=31:mi=31:no=37:*=37'

# cd
abbr --add --global -- - 'cd -'

# python
# Don't add the name of the virtual environment to my prompt. This way, I can add it myself
# using the same formatting as the rest of my prompt.
set --global --export VIRTUAL_ENV_DISABLE_PROMPT 1
function python --wraps python
    if type --query ipython
    # Make sure ipython belongs to the current python installation.
    #
    # If I pipe the output of python to grep, python will raise a BrokenPipeError. To avoid this, I use echo to pipe
    # the output.
    and echo (command python -m pip list) | grep -q ipython
        if test (count $argv) -eq 0
        or contains -- '-i' $argv
            ipython $argv
            return
        end
    end
    command python $argv
end

# ripgrep
set --global --export RIPGREP_CONFIG_PATH "$HOME/.ripgreprc"

# zoxide
set --global --export _ZO_FZF_OPTS "$FZF_DEFAULT_OPTS --preview 'lsd {2}' --keep-right --height 40% --preview-window '50%'"
zoxide init --cmd cd fish | source
# overwrite the cd function that zoxide creates to handle the '--' argument
function cd --wraps cd
    # zoxide does not support the '--' argument
    if set index (contains --index -- '--' $argv)
        set --erase argv[$index]
    end
    __zoxide_z $argv
end

# direnv
if type --query direnv
    direnv hook fish | source
    # toggle activation/deactivation messages
    set --global --export DIRENV_LOG_FORMAT (set_color brwhite)'[direnv] %s'(set_color normal)
end

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

# comma
function , --wraps ,
    # The `--with-nth` to remove the '.out' extension from the entries.
    FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --height 30% --no-preview --no-header --delimiter '.' --with-nth '..-5'" COMMA_PICKER=fzf command , $argv
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

# Launch a program and detach from it. Meaning it will be disowned and its output will be suppressed
# TODO: Have it wrap sudo so it autocompletes program names.
# I should write my own completion script though since this will
# also autocomplete sudo flags.
function detach --wraps sudo
  # Redirecting the i/o files on the command itself still resulted in some output being sent to the
  # terminal, but putting the command in a block and redirecting the i/o files of the block does
  # the trick.
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

function tree --wraps tree
  # If stdin is not connected to a terminal, we assume it's connected to a pipe.
  # In which case, have tree take its input from stdin.
  if not isatty stdin
    command tree -a --fromfile .
    return $status
  end

  # If there are no arguments, get files from fd since fd will exclude anything in a .gitignore or .ignore file.
  if test (count $argv) -eq 0
    fd | command tree -a --fromfile .
    return $status
  end

  # If there is just one argument, we'll assume that it's a directory and pass it to fd for reasons stated in the case
  # above.
  if test (count $argv) -eq 1
    fd . "$argv[1]" | command tree -a --fromfile .
    return $status
  end

  command tree -a $argv
  return $status
end

function dig --wraps doggo
    doggo --color=false $argv
end

function df --wraps duf
    env NO_COLOR=1 duf $argv
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
    yash $argv
end

if type --query flatpak
and flatpak list --app | grep -q 'org.wezfurlong.wezterm'
    alias wezterm 'flatpak run org.wezfurlong.wezterm'
end

# wrapping for the autocomplete
function myssh --wraps ssh
    command myssh $argv
end

# Sometimes vendor configs add to the PATH, but I want my ~/.local/bin to be first, in case I want to wrap one of
# the vendor programs. Since this file is sourced after vendor configs I set it here.
fish_add_path --prepend --move "$HOME/.local/bin"

if uname | grep -q Linux
    abbr --add --global trash 'trash put'
end

alias chase 'chase --verbose'
