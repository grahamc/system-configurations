# Normally I check if the shell is interactive, but I need to run this even when the shell is
# non-interactive so when fzf is launched from vscode, it picks up my FZF_DEFAULT_OPTS.

set --local xdg_data (test -n "$XDG_DATA_HOME" && echo "$XDG_DATA_HOME" || echo "$HOME/.local/share")

function __flag
    set name $argv[1]
    set values $argv[2..]
    if test (count $values) -gt 0
        printf '--%s=\'%s\'' $name (string join -- ',' $values)
    else
        printf '--%s' $name
    end
end

set --global _bigolu_preview_indicators "  " "+  "
set --global _bigolu_help_preview_indicator $_bigolu_preview_indicators[1]
set --global _bigolu_selected_preview_indicator $_bigolu_preview_indicators[2]
function _bigolu_remove_preview_indicators --argument-names str
    for indicator in $_bigolu_preview_indicators
        set str (string replace -- "$indicator" "" "$str")
    end
    echo -n "$str"
end

# TODO: I use the indicator to tell which state we are in, but if fzf adds a variable for the
# content of the 'info' section, I could just use that since they put a '+T' in there when you're
# tracking.
function _bigolu_track_toggle
    set indicator "  "
    set new "$FZF_PROMPT"
    if set new (string replace -- "$indicator" "" "$new")
        set bind "rebind(change)"
    else
        set new "$indicator$FZF_PROMPT"
        set bind "unbind(change)"
    end
    echo "toggle-track+change-prompt($new)+$bind"
end

# TODO: I use the indicator to tell which state we are in, but if fzf adds a variable for the
# content of the preview label, I could just use that.
function _bigolu_help_toggle
    set new "$FZF_PROMPT"
    if set new (string replace -- "$_bigolu_help_preview_indicator" "" "$new")
        set action refresh-preview
    else
        set new (_bigolu_remove_preview_indicators "$new")
        set new "$_bigolu_help_preview_indicator$new"
        set action "preview(fzf-help-preview)+preview-top"
    end
    echo "$action+change-prompt($new)"
end

# TODO: I use the indicator to tell which state we are in, but if fzf adds a variable for the
# content of the preview label, I could just use that.
function _bigolu_selected_toggle
    set new "$FZF_PROMPT"
    if set new (string replace -- "$_bigolu_selected_preview_indicator" "" "$new")
        set action refresh-preview
    else
        set new (_bigolu_remove_preview_indicators "$new")
        set new "$_bigolu_selected_preview_indicator$new"
        set action "preview(printf %s\n {+})+preview-top"
    end
    echo "$action+change-prompt($new)"
end

# Certain actions can cause fzf to leave the help/selected-entries preview.  After executing one of
# those actions, we need to see the prompt back to the original.
#
# TODO: I should also run this on the 'focus' event, but it makes selecting items very slow.
function _bigolu_fix_prompt
    echo "change-prompt($(_bigolu_remove_preview_indicators $FZF_PROMPT))"
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
    (__flag 'info' 'inline') \
    (__flag 'pointer' '>') \
    (__flag 'marker' '+') \
    (__flag 'history' "$xdg_data/fzf/fzf-history.txt") \
    (__flag 'preview' 'printf %s\n {+}') \
    (__flag 'preview-window' 'wrap' 'bottom' '40%') \
    (__flag 'multi') \
    (__flag 'no-separator') \
    (__flag 'scrollbar' '🮉') \
    (__flag 'preview-label' " $(set_color magenta)ctrl+h$(set_color normal) toggle help ") \
    (__flag 'preview-label-pos' '-3:bottom') \
    (__flag 'ansi') \
    (__flag 'tabstop' '2') \
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
    ) \
    (__flag 'bind' \
        'tab:down' \
        'shift-tab:up' \
        'ctrl-j:preview-down' \
        'ctrl-k:preview-up' \
        'change:first' \
        'enter:accept' \
        'ctrl-w:toggle-preview-wrap' \
        'alt-enter:toggle' \
        'f7:prev-history' \
        'f8:next-history' \
        'ctrl-p:toggle-preview' \
        'alt-a:toggle-all' \
        'ctrl-t:transform(_bigolu_track_toggle)' \
        'ctrl-h:transform(_bigolu_help_toggle)' \
        'ctrl-s:transform(_bigolu_selected_toggle)' \
        'ctrl-r:refresh-preview+transform(_bigolu_fix_prompt)' \
        'resize:refresh-preview+transform(_bigolu_fix_prompt)' \
        'ctrl-o:change-preview-window(right,60%|bottom,75%)+refresh-preview+transform(_bigolu_fix_prompt)' \
    )

set --export FZF_DEFAULT_OPTS (string join -- ' ' $flags)
