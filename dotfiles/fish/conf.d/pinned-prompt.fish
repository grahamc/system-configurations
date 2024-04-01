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

function _bigolu_pinned_prompt_pin_after_window_resize --on-signal WINCH
    if set --query --global _bigolu_no_winch
        set --global --erase _bigolu_no_winch
        return
    end
    set --global total_lines (tput lines)
    # https://stackoverflow.com/questions/8343250/how-can-i-get-position-of-cursor-in-terminal
    echo -ne "\033[6n"
    set --global current_line (string match --regex --groups-only -- '\[([0-9]+)\;' (_bigolu_pinned_prompt_read_until 'R'))

    if test $current_line -lt $total_lines
        _bigolu_pinned_prompt_clear_from_prompt_above_cursor_to_bottom
        _bigolu_pinned_prompt_move_cursor_to_last_line
    end
end

function _bigolu_pinned_prompt_open_widget --argument-names widget_opener height
    if set --export --query TMUX
        set visible_pane (tmux capture-pane -e -p -S 0 -E -)
        set prompt $visible_pane[(math $LINES - $bigolu_prompt_lines)..]

        set widget_and_prompt_height (math $bigolu_prompt_lines + $height)
        set end (math $LINES - 1)
        set start (math $end - \($widget_and_prompt_height - 1 \))
        set --global lines_to_restore $visible_pane[$start..$end]

        _bigolu_pinned_prompt_move_cursor_up $widget_and_prompt_height
        tput ed
        string join -- \n $prompt
    end

    eval $widget_opener

    if set --export --query TMUX
        _bigolu_pinned_prompt_move_cursor_up (math $bigolu_prompt_lines + 1)
        tput ed
        string join -- \n $lines_to_restore
    else
        _bigolu_pinned_prompt_clear_from_prompt_above_cursor_to_bottom
        _bigolu_pinned_prompt_move_cursor_to_last_line
    end
end

function _bigolu_pinned_prompt_read_until --argument-names target
    set buffer
    set char
    while test "$char" != "$target"'.'
        set char (echo -n (dd bs=1 count=1 2>/dev/null; echo '.') | cat --show-all)
        set buffer "$buffer$char"
    end

    echo -n (string replace --all '.' '' "$buffer")
end

function _bigolu_pinned_prompt_clear_from_prompt_above_cursor_to_bottom
    _bigolu_pinned_prompt_move_cursor_up (math $bigolu_prompt_lines - 1)
    tput ed
end

function _bigolu_pinned_prompt_move_cursor_up --argument-names count
    tput cuu $count
    echo -ne "\r"
end

function _bigolu_pinned_prompt_move_cursor_to_last_line
    tput cup $LINES 0
end
