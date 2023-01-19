#!/bin/env sh

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

if ! [ -d ~/.dotfiles ]; then
  git clone git@github.com:bigolu/dotfiles.git ~/.dotfiles
fi
cd ~/.dotfiles

# Run Dotbot
./install/install

printf 'Finished!\n\nNOTE: The current login session doesn'\''t have the settings in the newly linked login shell profile so you should relogin to apply those settings. Otherwise, you'\''ll have issues like not being able to use the tools installed by homebrew, nix, etc.\n'
