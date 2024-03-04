# Normally I check if the shell is interactive, but I need to run this even when the shell is
# non-interactive so when fzf is launched from vscode, it picks up my FZF_DEFAULT_OPTS.

set --local xdg_data (test -n "$XDG_DATA_HOME" && echo "$XDG_DATA_HOME" || echo "$HOME/.local/share")
set --local _fzf_history_file "$xdg_data/fzf/fzf-history.txt"
set --local _magnifying_glass \uf002'  '

# TODO: I use the indicator to tell which state we are in, but if fzf adds a variable for the
# content of the 'info' section, I could just use that since they put a '+T' in there when you're
# tracking.
set __track_toggle '
    set indicator "  "
    set new $FZF_PROMPT
    if set new (string replace -- $indicator "" $new)
        set bind "rebind(change)"
    else
        set new $indicator$FZF_PROMPT
        set bind "unbind(change)"
    end
    echo "toggle-track+change-prompt($new)+$bind"
'

# TODO: I use the indicator to tell which state we are in, but if fzf adds a variable for the
# content of the preview label, I could just use that.
set __help_toggle '
    set indicator "  "
    set new $FZF_PROMPT
    if set new (string replace -- $indicator "" $new)
        set action "refresh-preview"
    else
        set new (string replace -- "+  " "" $new)
        set new $indicator$new
        set action "preview(fzf-help-preview)+preview-top"
    end
    echo "$action+change-prompt($new)"
'

# TODO: I use the indicator to tell which state we are in, but if fzf adds a variable for the
# content of the preview label, I could just use that.
set __selected_toggle '
    set indicator "+  "
    set new $FZF_PROMPT
    if set new (string replace -- $indicator "" $new)
        set action "refresh-preview"
    else
        set new (string replace -- "  " "" $new)
        set new $indicator$new
        set action "preview(printf %s\n {+})+preview-top"
    end
    echo "$action+change-prompt($new)"
'

# Certain actions can cause fzf to leave the help/selected-entries preview besides pressing their
# keybind. After executing one of those actions, we need to see the prompt back to the original.
set __fix_prompt '
    set new $FZF_PROMPT
    set new (string replace -- "  " "" $new)
    set new (string replace -- "+  " "" $new)
    echo "change-prompt($new)"
'

# You can't have whitespace in the `--bind` or `--color` argument which is why they're formatted
# differently than the other flags.
#
# Some binds are separate from the others so I can use the ':' syntax and not have to escape
# anything in my command.
set --global --export FZF_DEFAULT_OPTS " \
--bind '\
tab:down,\
shift-tab:up,\
ctrl-j:preview-down,\
ctrl-k:preview-up,\
change:first,\
enter:accept,\
ctrl-w:toggle-preview-wrap,\
alt-enter:toggle,\
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
    --preview='printf %s\n {+}' \
    --preview-window=wrap,bottom,40% \
    --multi \
    --no-separator \
    --scrollbar='🮉 ' \
    --preview-label ' $(set_color magenta)ctrl+h$(set_color normal) toggle help ' \
    --preview-label-pos '-3:bottom' \
    --ansi \
    --tabstop 2 \
    --bind 'ctrl-t:transform:$__track_toggle' \
    --bind 'ctrl-h:transform:$__help_toggle' \
    --bind 'ctrl-s:transform:$__selected_toggle' \
    --bind 'focus:transform:$__fix_prompt' \
    --bind 'ctrl-r:refresh-preview+transform:$__fix_prompt' \
    --bind 'resize:refresh-preview+transform:$__fix_prompt' \
    --bind 'ctrl-o:change-preview-window(right,60%|bottom,75%)+refresh-preview+transform:$__fix_prompt' \
    "
