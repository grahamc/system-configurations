function fish_right_prompt
  # transient prompt
  if set --query TRANSIENT_RIGHT
      set --erase TRANSIENT_RIGHT
      echo -n ' '
      return
  else if set --query TRANSIENT_EMPTY_RIGHT
      set --erase TRANSIENT_EMPTY_RIGHT
      echo -n ' '
      return
  end

  # echo -s (set_color brwhite) '(ctrl+/: help)' (set_color normal)
  echo -s (set_color brwhite) '' (set_color normal)
end
