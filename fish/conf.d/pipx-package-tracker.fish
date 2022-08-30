if not status is-interactive
    exit
end

function pipx --wraps pipx
  command pipx $argv
  set exit_code $status

  # All commands that should trigger a backup
  set backup_commands install uninstall uninstall-all
  set pipx_subcommand "$argv[1]"
  if contains -- "$pipx_subcommand" $backup_commands
    pipx list --short | string split --fields 1 ' ' > ~/.config/pipx/pipx-packages
  end

  return $exit_code
end
