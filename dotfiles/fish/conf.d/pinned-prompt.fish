if not status is-interactive
    exit
end

bind \cl 'string repeat --count $LINES \n; commandline -f repaint'

function fish
    BIGOLU_NO_PROMPT_PUSH=1 command fish $argv
end

function _bigolu_pinned_prompt_pin_at_startup --on-event fish_prompt
    # I only want this to run once so delete the function.
    functions -e (status current-function)
    if not set --export --query BIGOLU_NO_PROMPT_PUSH
        # push prompt to the bottom
        string repeat --count $LINES \n
    else
        set --erase BIGOLU_NO_PROMPT_PUSH
    end
end

function _bigolu_pinned_prompt_set_line_count --on-event fish_prompt
    # I only want this to run once so delete the function.
    functions -e (status current-function)
    functions --copy fish_prompt _bigolu_pinned_prompt_old_fish_prompt
    function fish_prompt
        set prompt "$(_bigolu_pinned_prompt_old_fish_prompt)"
        set --global bigolu_prompt_lines (echo -n $prompt | wc -l)
        echo "$prompt"
    end
end

# TODO: Would be nice if I could avoid the blank lines that get added to the scrollback. zsh4humans
# gets around this by moving the cursor up, for example with `tput cuu1`, by the height of the
# widget, saving the contents of the lines that will now get overwritten by the widget with `tmux
# capture-pane`, and restoring the contents when the widget closes:
#
# save screen: https://github.com/romkatv/zsh4humans/blob/5fd088565ca494ca8b8564ad4dc81fdaf13e2e9d/fn/-z4h-save-screen
# restore screen: https://github.com/romkatv/zsh4humans/blob/5fd088565ca494ca8b8564ad4dc81fdaf13e2e9d/fn/-z4h-restore-screen
function _bigolu_pinned_prompt_pin_after_widget_closes --on-event bigolu_post_widget
    # TODO: This could be a little simpler if fish let `commandline -f` run synchronously. In that
    # case I could do repaint and make the prompt empty, then move to the bottom of the screen and
    # repaint again:
    # https://github.com/fish-shell/fish-shell/issues/3031
    _bigolu_clear_prompt
    tput cup $LINES 0
end

function _bigolu_pinned_prompt_pin_after_window_resize --on-signal WINCH
    # TODO: This doesn't work properly outside of TMUX, specifically in wezterm
    if not set --export --query TMUX
        return
    end

    set --global total_lines (tput lines)
    # https://stackoverflow.com/questions/8343250/how-can-i-get-position-of-cursor-in-terminal
    echo -ne "\033[6n"
    set --global current_line (string match --regex --groups-only -- '\[([0-9]+)\;' (read_until 'R'))

    if test $current_line -lt $total_lines
        _bigolu_clear_prompt
        tput cup $LINES 0
    end
end

function read_until --argument-names target
    set buffer
    set char
    while test "$char" != "$target"'.'
        set char (echo -n (dd bs=1 count=1 2>/dev/null; echo '.') | cat --show-all)
        set buffer "$buffer$char"
    end

    echo -n (string replace --all '.' '' "$buffer")
end

function _bigolu_clear_prompt
    tput cuu (math $bigolu_prompt_lines - 1)
    string repeat --count $bigolu_prompt_lines (string repeat --count $COLUMNS ' ')
end
