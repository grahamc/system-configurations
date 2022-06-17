function brew --wraps brew
  command brew $argv
  set exit_code $status

  # By backgrounding this command in a subshell, this shell won't be its parent, the subshell will.
  # Now tmux-resurrect won't think that this backgrounded command is the command to resurrect.
  fish -c 'chronic brew bundle dump --force --file ~/.config/brewfile/Brewfile &'

  return $exit_code
end
