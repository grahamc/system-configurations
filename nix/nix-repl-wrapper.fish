#!/usr/bin/env fish

set wrapper_nix (realpath --no-symlinks (status current-filename))
set real_nix "$(which -a nix | grep -v -E "^$wrapper_nix\$" | head -1)"

# If I'm starting the repl, start it with my startup file.
if test (count $argv) -eq 1 -a $argv[1] = repl
  set xdg_config (test -n "$XDG_CONFIG_HOME" && echo $XDG_CONFIG_HOME || echo "$HOME/.config")
  set --append argv --file "$xdg_config/nix/repl-startup.nix"
end

$real_nix $argv
