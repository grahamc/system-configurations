function tree --wraps tree
  # If stdin is not connected to a terminal, we assume it's connected to a pipe.
  # In which case, have tree take its input from stdin.
  if not isatty stdin
    command tree --fromfile .
    return $status
  end

  if type --query fd
    # If there are no arguments, get files from fd since fd will exclude anything in a .gitignore or .ignore file.
    if test (count $argv) -eq 0
      fd | command tree --fromfile .
      return $status
    end

    # If there is just one argument, we'll assume that it's a directory and pass it to fd for reasons stated in the case
    # above.
    if test (count $argv) -eq 1
      fd . "$argv[1]" | command tree --fromfile .
      return $status
    end
  end


  command tree $argv
  return $status
end
