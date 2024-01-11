#!/usr/bin/env fish

function stack_move --argument-names direction
    if test "$direction" = down
        # If there's no next window in the stack, wrap around.
        yabai -m window --focus stack.next || yabai -m window --focus stack.first
    else
        # If there's no previous window in the stack, wrap around.
        yabai -m window --focus stack.prev || yabai -m window --focus stack.last
    end
end

function window_move --argument-names direction
    if test "$direction" = down
        yabai -m window --focus south
    else
        yabai -m window --focus north
    end
end

function move --argument-names direction
    # window is not in a stack
    if yabai -m query --windows --window | jq --exit-status '."stack-index" == 0' 1>/dev/null 2>&1
        window_move $direction
        # window is in a stack
    else
        set current_window_id (yabai -m query --windows --window | jq --raw-output '.id')
        set first_window_id (yabai -m query --windows --window stack.first | jq --raw-output '.id')
        set last_window_id (yabai -m query --windows --window stack.last | jq --raw-output '.id')
        # window is first in the stack
        if test $current_window_id = $first_window_id
            if test $direction = up
                window_move $direction
            else
                stack_move $direction
            end
            # window is last in the stack.
        else if test $current_window_id = $last_window_id
            if test $direction = down
                window_move $direction
            else
                stack_move $direction
            end
            # window is somewhere in the middle of the stack
        else
            stack_move $direction
        end
    end
end

move $argv
