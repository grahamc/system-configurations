#!/usr/bin/env bash

# user direnv
printf '%s\0' "$HOME/.direnvrc"
printf '%s\0' "$HOME/.config/direnv/direnvrc"

printf '%s\0' "$PWD/flake.nix"
printf '%s\0' "$PWD/flake.lock"
printf '%s\0' "$PWD/flake-modules/dev-shell.nix"
find "$PWD/secrets" -type f \! -name .DS_Store -print0
# Adding this so if .direnv doesn't exist, the environment will be considered stale
printf '%s\0' "$PWD/.direnv/CACHEDIR.TAG"
