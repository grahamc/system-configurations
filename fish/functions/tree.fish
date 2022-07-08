function tree --wraps tree
  if isatty stdin
    command tree $argv
    return $status
  end

  # If stdin is not connected to a terminal, we assume it's connected to a pipe.
  # In which case, have tree take its input from stdin.
  command tree --fromfile .
end
