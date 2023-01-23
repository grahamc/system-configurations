#!/bin/sh

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

# Dependencies for the plugin telescope-fzf-native.nvim
sudo apt install --yes g++ cmake

if ! [ -f ~/.local/share/nvim/vim-plug-snapshot.vim ]; then
  nvim -c qall
  nvim -c 'autocmd VimEnter * PlugRestore' -c 'autocmd VimEnter * qall'
fi
