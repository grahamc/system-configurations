function brew --wraps brew
  command brew $argv
  set exit_code $status

  # All commands that should trigger a dump
  set dump_commands install uninstall remove rm
  set brew_subcommand "$argv[1]"
  if contains -- "$brew_subcommand" $dump_commands
    command brew bundle dump --force --file ~/.config/brewfile/Brewfile
  end

  return $exit_code
end
