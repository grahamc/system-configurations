if not status is-interactive
    exit
end

set --global --export FZF_DEFAULT_OPTS "
    --cycle
    --ellipsis='…'
    --bind 'tab:down,shift-tab:up,alt-down:preview-page-down,alt-up:preview-page-up,change:first,alt-o:change-preview-window(right,border-left|bottom,border-top),ctrl-/:preview(fzf-help-preview),ctrl-\\:refresh-preview,enter:select+accept'
    --layout=reverse
    --border=rounded
    --color='16,fg+:-1:regular,bg+:-1,fg:dim,info:black,gutter:bright-black,pointer:14:regular,prompt:14:regular,border:black,query:-1:regular,marker:14:regular,header:black,spinner:14,hl:cyan:dim,hl+:regular:cyan'
    --margin=5%
    --padding=3%
    --height 100%
    --prompt='> '
    --tabstop=4
    --info='inline'
    --pointer='❯'
    --marker='❯'
    --history='$HOME/.fzf.history'
    --header='(Press ctrl+/ for help)'
    --preview='echo Current selection: {}'
    --preview-window=wrap,bottom,border-top,60%"
set --global --export FZF_ALT_C_COMMAND "fd --hidden --strip-cwd-prefix --type directory"
set --global --export FZF_ALT_C_OPTS "--preview 'ls --classify -x {}' --keep-right --bind='change:first'"
set --global --export FZF_CTRL_T_COMMAND 'fd --hidden --strip-cwd-prefix --type file'
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
# TODO: This won't work until the bugfix commit gets added to a release so I'll print an error instead for now.
# bugfix: https://github.com/junegunn/fzf/pull/2799
# bind \ed 'FZF_ALT_C_OPTS="$FZF_ALT_C_OPTS --prompt=\'$(prompt_pwd)/\'" fzf-cd-widget'
bind \ed "commandline --replace \"echo -e -s (set_color red) 'ERROR: This keybind does not work due to a bug in fzf. The bug has been fixed, but the commit hasn\'t been added to a release yet: https://github.com/junegunn/fzf/pull/2799' (set_color normal)\"; set --global TRANSIENT; commandline -f repaint; commandline -f execute"

bind \cg 'fzf-grep-widget'

# Workaround to allow me to use fzf-tmux-zoom with the default widgets that come with fzf.
# The default widgets use __fzfcmd to get the name of the fzf command to use so I am
# overriding it here.
function __fzfcmd
    echo fzf-tmux-zoom
end
