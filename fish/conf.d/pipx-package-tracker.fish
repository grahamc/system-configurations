if not status is-interactive
    exit
end

function pipx --wraps pipx
  command pipx $argv
  set exit_code $status

  # By backgrounding this command in a subshell, this shell won't be its parent, the subshell will.
  # Now tmux-resurrect won't think that this backgrounded command is the command to resurrect.
  fish -c 'flock --timeout 300 /tmp/pipx-package-tracker-lock --command "pipx list --json > ~/.config/pipx/pipx-packages.json" &'

  return $exit_code
end
