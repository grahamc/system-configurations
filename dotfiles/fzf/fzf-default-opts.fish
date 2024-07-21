# Normally I check if the shell is interactive, but I need to run this even when
# the shell is non-interactive so I can call the fish functions defined here
# from fzf bindings.

set --local xdg_data (test -n "$XDG_DATA_HOME" && echo "$XDG_DATA_HOME" || echo "$HOME/.local/share")

set _bigolu_fzf_help_text " $(set_color magenta)ctrl+h$(set_color normal) show help page "

function __flag
    set name $argv[1]
    set values $argv[2..]
    if test (count $values) -gt 0
        printf '--%s=\'%s\'' $name (string join -- ',' $values)
    else
        printf '--%s' $name
    end
end

# TODO: I use the indicator to tell which state we are in, but if fzf adds a
# variable for the content of the 'info' section, I could just use that since
# they put a '+T' in there when you're tracking.
function _bigolu_track_toggle
    set indicator "  "
    set new "$FZF_PROMPT"
    if set new (string replace -- "$indicator" "" "$new")
        set bind "rebind(change)"
    else
        set new "$indicator$FZF_PROMPT"
        set bind "unbind(change)"
    end
    echo "toggle-track+change-prompt($new)+$bind"
end

function _bigolu_fzf_preview_toggle --argument-names name keybind preview
    if not string match --quiet --regex -- ".*$name.*go back.*" "$FZF_BORDER_LABEL"
        echo "preview($preview)+preview-top+change-border-label@ $name ($(set_color magenta)$keybind$(set_color normal) to go back) @"
    else
        echo "refresh-preview+change-border-label@$_bigolu_fzf_help_text@"
    end
end

function _bigolu_selected_toggle
    _bigolu_fzf_preview_toggle 'selected items' 'ctrl+s' 'printf %s\n {+}'
end

function _bigolu_help_toggle
    _bigolu_fzf_preview_toggle 'help page' 'ctrl+h' fzf-help-preview
end

# Certain actions can cause fzf to leave the help/selected-entries preview.
# After executing one of those actions, we need to see the label back to the
# original.
#
# TODO: I should also run this on the 'focus' event, but it makes selecting
# items very slow.
function _bigolu_fix_label
    echo "change-border-label($_bigolu_fzf_help_text)"
end

set flags \
    (__flag 'cycle') \
    (__flag 'ellipsis' '…') \
    (__flag 'layout' 'reverse') \
    (__flag 'border' 'none') \
    (__flag 'margin' '5%') \
    (__flag 'height' '100%') \
    (__flag 'min-height' '4') \
    (__flag 'prompt' '  ') \
    (__flag 'tabstop' '2') \
    (__flag 'info' 'inline-right') \
    (__flag 'separator' '─') \
    (__flag 'history' "$xdg_data/fzf/fzf-history.txt") \
    (__flag 'preview' 'printf %s\n {+}') \
    (__flag 'preview-window' 'wrap' 'bottom' '40%' 'border-top') \
    (__flag 'multi') \
    (__flag 'scrollbar' '🮉') \
    (__flag 'border-label' "$_bigolu_fzf_help_text") \
    (__flag 'border-label-pos' '-3:bottom') \
    (__flag 'ansi') \
    (__flag 'tabstop' '2') \
    (__flag 'border' 'rounded') \
    (__flag 'wrap') \
    (__flag 'color' \
        '16' \
        'fg+:-1:regular:underline' \
        'bg+:-1' \
        'info:8' \
        'gutter:-1' \
        'pointer:6:bold' \
        'prompt:6:regular' \
        'border:8' \
        'query:-1:regular' \
        'marker:6:bold' \
        'header:8' \
        'spinner:yellow' \
        'hl:cyan' \
        'hl+:regular:cyan:underline' \
        'scrollbar:8:dim' \
        'preview-scrollbar:8:dim' \
    ) \
    (__flag 'bind' \
        'tab:down' \
        'shift-tab:up' \
        'ctrl-j:preview-down' \
        'ctrl-k:preview-up' \
        'change:first' \
        'enter:accept' \
        'ctrl-w:toggle-preview-wrap' \
        'alt-w:toggle-wrap' \
        'alt-enter:toggle' \
        'f7:prev-history' \
        'f8:next-history' \
        'ctrl-p:toggle-preview+transform(_bigolu_fix_label)' \
        'alt-a:toggle-all' \
        'ctrl-t:transform(_bigolu_track_toggle)' \
        'ctrl-h:transform(_bigolu_help_toggle)' \
        'ctrl-s:transform(_bigolu_selected_toggle)' \
        'ctrl-r:refresh-preview+transform(_bigolu_fix_label)' \
        'resize:refresh-preview+transform(_bigolu_fix_label)' \
        'ctrl-o:change-preview-window(right,60%,border-left|bottom,75%,border-top)+refresh-preview+transform(_bigolu_fix_label)' \
    )

set --export FZF_DEFAULT_OPTS (string join -- ' ' $flags)
