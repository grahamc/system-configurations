#!/bin/sh

# Assign stdin, stdout, and stderr to the terminal
exec </dev/tty >/dev/tty 2>/dev/tty

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

changed_filenames="$(git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD)"
changed_filenames_with_status="$(git diff-tree -r --name-status ORIG_HEAD HEAD)"

has_changes() {
  echo "$changed_filenames" | grep --extended-regexp --quiet "$1"
}

has_added_file() {
  if [ "$#" -eq 0 ]; then
    echo "$changed_filenames_with_status" | grep --extended-regexp --quiet "^A"
  else
    echo "$changed_filenames_with_status" | grep --extended-regexp --quiet "^A\s+$1"
  fi
}

has_deleted_file() {
  if [ "$#" -eq 0 ]; then
    echo "$changed_filenames_with_status" | grep --extended-regexp --quiet "^D"
  else
    echo "$changed_filenames_with_status" | grep --extended-regexp --quiet "^D\s+$1"
  fi
}

confirm() {
  printf "%s (y/n): " "$1"
  read -r answer
  [ "$answer" = 'y' ]
}

# With this, even if a command fails the script will continue
suppress_error() {
  "$@" || true
}

if has_added_file || has_deleted_file; then
  if confirm 'A file has been added and/or deleted, would you like dotbot to relink?'; then
    suppress_error ./install/install --only clean link
  fi
fi

fish_plugins='fish/fish_plugins'
if has_changes "$fish_plugins"; then
  if confirm "Changes have been made to $fish_plugins would you like fisher to update from it?"; then
    suppress_error fish -c 'source ~/.config/fish/functions/fisher.fish; fisher update'
  fi
fi

brewfile='brew/Brewfile'
if has_changes "$brewfile"; then
  if confirm "Changes have been made to $brewfile would you like brew to update from it?"; then
    suppress_error brew bundle install --file "$brewfile"
  fi
fi

vim_plug_snapshot='neovim/vim-plug-snapshot.vim'
if has_changes "$vim_plug_snapshot"; then
  if confirm "Changes have been made to $vim_plug_snapshot would you like neovim to update from it?"; then
    suppress_error nvim -c 'autocmd VimEnter * PlugRestore'
  fi
fi

tool_versions='asdf/tool_versions'
if has_changes "$tool_versions"; then
  if confirm "Changes have been made to $tool_versions would you like asdf to update from it?"; then
    suppress_error asdf install
  fi
fi

pipx_packages='pipx/pipx-packages'
if has_changes "$pipx_packages"; then
  if confirm "Changes have been made to $pipx_packages would you like pipx to update from it?"; then
    suppress_error xargs -I PACKAGE pipx install PACKAGE < "$pipx_packages"
  fi
fi

bat_theme_file_pattern='bat/.*\.tmTheme$'
if has_added_file "$bat_theme_file_pattern" || has_deleted_file "$bat_theme_file_pattern"; then
  if confirm "A bat theme has been added/removed would you like to rebuild the bat cache?"; then
    suppress_error bat cache --build
  fi
fi
