if not status is-interactive
    exit
end

set --local xdg_data (test -n "$XDG_DATA_HOME" && echo "$XDG_DATA_HOME" || echo "$HOME/.local/share")
set --local _fzf_history_file "$xdg_data/fzf/fzf-history.txt"
set --local _magnifying_glass \uf002'  '
set --local enter_help_hint ' press ctrl+/ for help '
set --local leave_help_hint ' press ctrl+\\ to go back '

# You can't have whitespace in the `--bind` or `--color` argument which is why they're formatted differently than
# the other flags.
set --global --export FZF_DEFAULT_OPTS " \
--bind '\
tab:down,\
shift-tab:up,\
ctrl-j:preview-down,\
ctrl-k:preview-up,\
change:first,\
ctrl-o:change-preview-window(right,60%|bottom,75%)+refresh-preview+change-preview-label($enter_help_hint),\
ctrl-/:preview(fzf-help-preview)+preview-top+change-preview-label($leave_help_hint),\
ctrl-\\:refresh-preview+change-preview-label($enter_help_hint),\
enter:accept,\
ctrl-r:refresh-preview+change-preview-label($enter_help_hint),\
ctrl-w:toggle-preview-wrap,\
alt-enter:toggle,\
ctrl-t:track+unbind(change),\
focus:rebind(change)+change-preview-label($enter_help_hint),\
f7:prev-history,\
f8:next-history,\
ctrl-p:toggle-preview,\
alt-a:toggle-all\
' \
--color '\
16,\
fg+:-1:regular:underline,\
bg+:-1,\
info:15,\
gutter:-1,\
pointer:6:bold,\
prompt:6:regular,\
border:15,\
query:-1:regular,\
marker:6:bold,\
header:15,\
spinner:yellow,\
hl:cyan,\
hl+:regular:cyan:underline,\
scrollbar:15:dim\
' \
    --cycle \
    --ellipsis='…' \
    --layout=reverse \
    --border=none \
    --margin=5% \
    --height 100% \
    --min-height 4 \
    --prompt='$_magnifying_glass' \
    --tabstop=2 \
    --info=inline \
    --pointer='>' \
    --marker='+' \
    --history='$_fzf_history_file' \
    --preview='echo {}' \
    --preview-window=wrap,bottom,40% \
    --multi \
    --no-separator \
    --scrollbar='🮉 ' \
    --preview-label '$enter_help_hint' \
    --preview-label-pos '-3:bottom' \
    --ansi \
    --tabstop 2 \
    "
