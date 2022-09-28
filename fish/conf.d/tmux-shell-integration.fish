if not status is-interactive
    exit
end

if test -z "$TMUX"
    exit
end

function __last_command_output
    set pane (tmux capture-pane -e -p -J -S - -E - | string split \n)
    set start (tmux display -p '#{@output_begin}')
    set end (tmux display -p '#{@output_end}')
    string join -- \n $pane[$start..$end]
end

function __view_last_command_output_in_less
    echo "$(__last_command_output)" | less -+F

    # this should be done whenever a binding produces output (see: man bind)
    commandline -f repaint
end
bind \co __view_last_command_output_in_less

function __view_last_command_output_in_fzf
    echo "$(__last_command_output)" | fzf --ansi

    # this should be done whenever a binding produces output (see: man bind)
    commandline -f repaint
end
bind \eo __view_last_command_output_in_fzf

function __get_last_pane_line
    # the number returned from tmux is 0-based so add 1
    # since fish arrays are 1-based
    set cursor_line (math (tmux display -p '#{cursor_y}') + 1)
    set pane_line_count (count (tmux capture-pane -p -J -S - -E - | string split \n))

    # When getting the lines in the pane tmux will include any blank lines at the bottom that haven't been printed onto yet.
    # This removes those lines from the count.
    set blank_line_count (math $LINES - $cursor_line)
    set pane_line_count (math $pane_line_count - $blank_line_count)
    echo $pane_line_count
end

function __mark_output_begin --on-event fish_preexec
    tmux set-option -p '@output_begin' "$(__get_last_pane_line)"
end

function __mark_output_end --on-event fish_postexec
    set output_end (math (__get_last_pane_line) - 1)
    tmux set-option -p '@output_end' $output_end

    # if output is larger than screen, show tip
    set output_begin (tmux display -p '#{@output_begin}')
    set output_line_count (math \( $output_end - $output_begin \) + 1)
    if test $output_line_count -gt $LINES
        echo -e "\n[$(set_color yellow)tip$(set_color normal)] View the output of the last command in $(set_color blue)less$(set_color normal) with $(set_color blue)ctrl+o$(set_color normal) or $(set_color magenta)fzf$(set_color normal) with $(set_color magenta)alt+o$(set_color normal)"
    end
end
