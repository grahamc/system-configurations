if not status is-interactive
    exit
end

set _fzf_history_file "$HOME/.config/fzf/fzf-history.txt"

set --global --export FZF_DEFAULT_OPTS "
    --cycle
    --ellipsis='…'
    --bind 'tab:down,shift-tab:up,alt-down:preview-page-down,alt-up:preview-page-up,change:first,alt-o:change-preview-window(right,border-left|bottom,border-top),ctrl-/:preview(fzf-help-preview),ctrl-\\:refresh-preview,enter:select+accept,ctrl-r:refresh-preview'
    --layout=reverse
    --border=none
    --color='16,fg+:-1:regular,bg+:-1,fg:dim,info:black,gutter:bright-black,pointer:14:regular,prompt:14:regular,border:black:dim,query:-1:regular,marker:14:regular,header:black,spinner:yellow,hl:cyan:dim,hl+:regular:cyan'
    --margin=3%
    --height 100%
    --prompt='> '
    --tabstop=2
    --info='inline'
    --pointer='❯'
    --marker='❯'
    --history='$_fzf_history_file'
    --header='(Press ctrl+/ for help)'
    --preview='echo Current selection: {}'
    --preview-window=wrap,bottom,border-rounded,75%"

set --global --export FZF_ALT_C_COMMAND 'test $dir = '.' && set _args "--strip-cwd-prefix" || set _args '.' $dir; fd $_args --hidden --type directory --type symlink'
set --global --export FZF_ALT_C_OPTS "--preview 'ls --classify -x {}' --keep-right --bind='change:first'"

set --global --export FZF_CTRL_T_COMMAND 'test $dir = '.' && set _args "--strip-cwd-prefix" || set _args '.' $dir; fd $_args --hidden --type file --type symlink'
set --global --export FZF_CTRL_T_OPTS '--multi --preview "bat --paging=never --terminal-width (math $FZF_PREVIEW_COLUMNS - 2) {} | tail -n +2 | head -n -1" --keep-right --bind="change:first"'

set --global --export FZF_CTRL_R_OPTS '--prompt="history: " --preview "echo {}"'

# use ctrl+f for file search instead of default ctrl+t
bind --erase \ct
bind \cf 'FZF_CTRL_T_OPTS="$FZF_CTRL_T_OPTS --prompt=\'$(prompt_pwd)/\'" fzf-file-widget'

# use ctrl+h for history search instead of default ctrl+r
bind --erase \cr
bind \ch fzf-history-widget

# use alt+d for directory search instead of default alt+c
bind --erase \ec
# TODO: This won't work until the bugfix commit gets added to a release so I'll print an error instead for now.
# bugfix: https://github.com/junegunn/fzf/pull/2799
# bind \ed 'FZF_ALT_C_OPTS="$FZF_ALT_C_OPTS --prompt=\'$(prompt_pwd)/\'" fzf-cd-widget'
bind \ed "commandline --replace \"echo -e -s (set_color red) 'ERROR: This keybind does not work due to a bug in fzf. The bug has been fixed, but the commit hasn\'t been added to a release yet: https://github.com/junegunn/fzf/pull/2799' (set_color normal)\"; _transient_repaint; commandline -f execute"

bind \cg 'fzf-grep-widget'

# Workaround to allow me to use fzf-tmux-zoom with the default widgets that come with fzf.
# The default widgets use __fzfcmd to get the name of the fzf command to use so I am
# overriding it here.
function __fzfcmd
    echo fzf-tmux-zoom
end

mkdir -p (dirname $_fzf_history_file)
touch $_fzf_history_file
