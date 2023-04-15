# TODO: The script in conf.d for the plugin 'jorgebucaran/autopair.fish' is deleting my ctrl+h keybind
# that I define in here. As a workaround, I prefixed this file with 'zz-' so that it's the last script to run in
# conf.d and autopair won't be able to delete its keybinds.

if not status is-interactive
    exit
end

set _fzf_history_file "$HOME/.config/fzf/fzf-history.txt"
set _magnifying_glass (echo -s \uf002 '  ')

set --global --export FZF_DEFAULT_OPTS "
    --cycle
    --ellipsis='…'
    --bind 'tab:down,shift-tab:up,ctrl-j:preview-down,ctrl-k:preview-up,change:first,alt-o:change-preview-window(right,60%|bottom,75%)+refresh-preview,ctrl-/:preview(fzf-help-preview)+preview-top,ctrl-\\:refresh-preview,enter:accept,ctrl-r:refresh-preview,ctrl-w:toggle-preview-wrap'
    --layout=reverse
    --border=none
    --color='16,fg:dim,fg+:-1:regular:underline,bg+:-1,info:15,gutter:8,pointer:-1:bold,prompt:6:regular,border:15:dim,query:-1:regular,marker:-1:bold,header:15,spinner:yellow,hl:cyan:dim,hl+:regular:cyan:underline'
    --margin=3%
    --height 100%
    --prompt='$_magnifying_glass'
    --tabstop=2
    --info=inline
    --pointer='>'
    --marker='>'
    --history='$_fzf_history_file'
    --header='(Press ctrl+/ for help)'
    --preview='echo {}'
    --preview-window=wrap,bottom,border-sharp,75%"

set --global --export FZF_ALT_C_COMMAND 'test $dir = '.' && set _args "--strip-cwd-prefix" || set _args '.' $dir; fd $_args --follow --hidden --type directory --type symlink'
set --global --export FZF_ALT_C_OPTS "--preview 'type --query lsd; and lsd {}; or ls {}' --keep-right --bind='change:first'"

set --global --export FZF_CTRL_R_OPTS '--prompt="history: " --preview "echo {}"'

# use ctrl+f for file search instead of default ctrl+t
bind --erase \ct
bind-no-focus \cf 'my-fzf-file-widget'

# use ctrl+h for history search instead of default ctrl+r
bind --erase \cr
# If we chose an entry from the history widget, which is signified by an exit code of 0, then we set a flag
# that tells fish-abbreviation-tips not to display a tip. This way, I won't get reminded about an abbreviation when
# executing a command
# from the history
#
# I also merge the history so that the search will search across all fish sessions' histories.
bind-no-focus \ch 'history merge; fzf-history-widget && set -g __abbr_tips_used 1'

# use alt+d for directory search instead of default alt+c
bind --erase \ec
bind-no-focus \ed 'FZF_ALT_C_OPTS="$FZF_ALT_C_OPTS --prompt=\'$(prompt_pwd)/\'" fzf-cd-widget'

bind-no-focus \cg 'fzf-grep-widget'

# Workaround to allow me to use fzf-tmux-zoom with the default widgets that come with fzf.
# The default widgets use __fzfcmd to get the name of the fzf command to use so I am
# overriding it here.
function __fzfcmd
    echo fzf-tmux-zoom
end

mkdir -p (dirname $_fzf_history_file)
touch $_fzf_history_file
