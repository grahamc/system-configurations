function brew --wraps brew
  command brew $argv
  set exit_code $status

  # By backgrounding this command in a subshell, this shell won't be its parent, the subshell will.
  # Now tmux-resurrect won't think that this backgrounded command is the command to resurrect.
  # The '--nonblock' and 'sleep 10' is for debouncing.
  fish -c 'flock --nonblock /tmp/brew-package-tracker-lock --command "sleep 10 && chronic brew bundle dump --force --file ~/.config/brewfile/Brewfile" &'

  return $exit_code
end
