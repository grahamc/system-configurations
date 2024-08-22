#!/usr/bin/env fish

# Prints a cheatsheet for fzf keybinds. This is intended to be used in a call to
# preview() in fzf.
#
# Additional keybinds can be set in the FZF_HINTS environment variable,
# separated by '\n', in the format '<keybind>: <description>' (The format
# must be followed for it to be styled correctly). e.g. FZF_HINTS='ctrl+a:
# accept\nctrl+b:back'. This way you can add keybinds specific to an fzf
# invocation.
#
# Usage:
# FZF_HINTS='ctrl+a: additional binding' fzf --preview fzf-help-preview
#
# TODO: The hints inside here should be taken out and passed inside
# FZF_HINTS. This way the script doesn't have my keybinds hardcoded in it.

function _format_hint_section
    set section_name $argv[1]
    # TODO: display in a grid like ls
    set hints (printf %s\n $argv[2..] | grep --color=always -E '(^.*:)')
    echo -e -s (set_color --bold) $section_name '\n' (string join "\n" $hints) '\n'
end

function _fzf_help_preview
    set hint_sections \
        (_format_hint_section 'Navigation' 'shift+tab/tab: move up/down' 'alt+enter: select multiple items' 'ctrl-t: toggle tracking' 'alt-w: toggle wrap') \
        (_format_hint_section 'History' 'ctrl+[/]: go to previous/next entry in history') \
        (_format_hint_section 'Preview Window' 'ctrl+s: show selected entries' 'ctrl+p: toggle preview visibility' 'ctrl+r: refresh preview' 'ctrl+k/j: scroll preview window up/down one line' 'ctrl+w: toggle line wrap' 'ctrl+o: toggle preview window orientation') \
        (_format_hint_section 'Search Syntax' '\'<query>: exact match' '^<query>: prefix match' '<query>$: suffix match' '!<query>: inverse exact match' '!^<query>: inverse prefix exact match' '!<query>$: inverse suffix exact match' '<query1> <query2>: match all queries' '<query1> | <query2>: match any query')
    if set --query FZF_HINTS
        set widget_specific_hints (echo -e $FZF_HINTS)
        set --prepend hint_sections (_format_hint_section 'Widget-Specific' $widget_specific_hints)
    end

    echo -e (string join "\n" $hint_sections)
end

# I'm using a function so that my variables will have a function-local scope
_fzf_help_preview
