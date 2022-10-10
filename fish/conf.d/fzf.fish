if not status is-interactive
    exit
end

set _fzf_history_file "$HOME/.config/fzf/fzf-history.txt"

if test "$NERDFONT_ENABLE" = "1"
    set prompt \uf002'  '
else
    set prompt '> '
end

set --global --export FZF_DEFAULT_OPTS "
    --cycle
    --ellipsis='…'
    --bind 'tab:down,shift-tab:up,ctrl-j:preview-down,ctrl-k:preview-up,change:first,alt-o:change-preview-window(right,60%|bottom,75%)+refresh-preview,ctrl-/:preview(fzf-help-preview)+preview-top,ctrl-\\:refresh-preview,enter:select+accept,ctrl-r:refresh-preview,ctrl-w:toggle-preview-wrap'
    --layout=reverse
    --border=none
    --color='16,fg+:-1:regular,bg+:8,info:15,gutter:-1,pointer:6:regular,prompt:6:regular,border:15:dim,query:-1:regular,marker:6:regular,header:15,spinner:yellow,hl:cyan,hl+:regular:cyan'
    --margin=3%
    --height 100%
    --prompt='$prompt'
    --tabstop=2
    --info=inline
    --pointer=' '
    --marker='🢒'
    --history='$_fzf_history_file'
    --header='(Press ctrl+/ for help)'
    --preview='echo {}'
    --preview-window=wrap,bottom,border-sharp,75%"

set --global --export FZF_ALT_C_COMMAND 'test $dir = '.' && set _args "--strip-cwd-prefix" || set _args '.' $dir; fd $_args --hidden --type directory --type symlink'
set --global --export FZF_ALT_C_OPTS "--preview 'type --query lsd; and lsd --icon=always {}; or ls {}' --keep-right --bind='change:first'"

set --global --export FZF_CTRL_T_COMMAND 'test $dir = '.' && set _args "--strip-cwd-prefix" || set _args '.' $dir; fd $_args --hidden --type file --type symlink'
set --global --export FZF_CTRL_T_OPTS '--multi --preview "bat --paging=never --terminal-width (math $FZF_PREVIEW_COLUMNS - 2) {} | tail -n +2 | head -n -1" --keep-right --bind="change:first"'

set --global --export FZF_CTRL_R_OPTS '--prompt="history: " --preview "echo {}"'

# use ctrl+f for file search instead of default ctrl+t
bind --erase \ct
bind \cf 'FZF_CTRL_T_OPTS="$FZF_CTRL_T_OPTS --prompt=\'$(prompt_pwd)/\'" fzf-file-widget'

# use ctrl+h for history search instead of default ctrl+r
bind --erase \cr
# If we chose an entry from the history widget, which is signified by an exit code of 0, then we set a flag
# that tells fish-abbreviation-tips not to display a tip. This way, I won't get reminded about an abbreviation when
# executing a command
# from the history
bind \ch 'fzf-history-widget && set -g __abbr_tips_used 1'

# use alt+d for directory search instead of default alt+c
bind --erase \ec
bind \ed 'FZF_ALT_C_OPTS="$FZF_ALT_C_OPTS --prompt=\'$(prompt_pwd)/\'" fzf-cd-widget'

bind \cg 'fzf-grep-widget'

# Workaround to allow me to use fzf-tmux-zoom with the default widgets that come with fzf.
# The default widgets use __fzfcmd to get the name of the fzf command to use so I am
# overriding it here.
function __fzfcmd
    echo fzf-tmux-zoom
end

mkdir -p (dirname $_fzf_history_file)
touch $_fzf_history_file
