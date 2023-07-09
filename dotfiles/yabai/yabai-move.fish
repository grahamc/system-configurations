#!/usr/bin/env fish

function move --argument-names direction
  if yabai -m query --windows --window | jq --exit-status '."stack-index" == 0' 1>/dev/null 2>&1
    if test "$direction" = 'down'
      yabai -m window --focus south
    else
      yabai -m window --focus north
    end
  else
    if test "$direction" = 'down'
      yabai -m window --focus stack.next || yabai -m window --focus stack.first
    else
      yabai -m window --focus stack.prev || yabai -m window --focus stack.last
    end
  end
end

move $argv
