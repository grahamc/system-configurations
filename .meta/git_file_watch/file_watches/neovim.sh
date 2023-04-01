#!/bin/sh

vim_plug_snapshot='neovim/vim-plug-snapshot.vim'
if has_changes "$vim_plug_snapshot"; then
  if confirm "The neovim plugin snapshot has changed, would you like neovim to update from it?"; then
    suppress_error nvim -c 'autocmd VimEnter * PlugRestore' -c 'autocmd VimEnter * qall'
  fi
fi
