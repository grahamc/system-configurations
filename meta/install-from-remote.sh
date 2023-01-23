#!/bin/sh

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

if ! [ -d ~/.dotfiles ]; then
  git clone https://github.com/bigolu/dotfiles.git ~/.dotfiles
fi
cd ~/.dotfiles

./dotfiles.sh profile && ./dotfiles.sh install
