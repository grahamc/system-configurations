function brew --wraps brew
  command brew $argv
  set exit_code $status

  chronic brew bundle dump --force --file ~/.config/brewfile/Brewfile &
  disown

  return $exit_code
end
