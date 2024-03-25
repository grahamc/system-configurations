#!/usr/bin/env bash

# user direnv
printf '%s\0' "$HOME/.direnvrc"
printf '%s\0' "$HOME/.config/direnv/direnvrc"

# firstaide
printf '%s\0' "$PWD/.firstaide/build_exe.bash"
printf '%s\0' "$PWD/.firstaide/watch_exe.bash"

printf '%s\0' "$PWD/flake.nix"
printf '%s\0' "$PWD/flake.lock"
printf '%s\0' "$PWD/../../flake-modules/smart-plug.nix"
# Adding this so if .direnv doesn't exist, the environment will be considered stale
printf '%s\0' "$PWD/.direnv/CACHEDIR.TAG"
