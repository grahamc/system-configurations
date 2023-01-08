#!/bin/sh

# Assign stdin, stdout, and stderr to the terminal
exec </dev/tty >/dev/tty 2>&1

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

# Contains each added/deleted/changed file. Each file is on its own line.
#
# Format:
# <status letter>    <filename relative to root of repo>
#
# For example, if the Brewfile was modified, this line would be present:
# M    brew/Brewfile
changed_filenames_with_status="$(git diff-tree -r --name-status ORIG_HEAD HEAD)"

# Exits with 0 if the specified file was added, deleted, or modified.
has_changes() {
  echo "$changed_filenames_with_status" | grep --extended-regexp --quiet "$1"
}

has_added_file() {
  echo "$changed_filenames_with_status" | grep --extended-regexp --quiet "^A"
}

has_deleted_file() {
  echo "$changed_filenames_with_status" | grep --extended-regexp --quiet "^D"
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

blue='\e[34m'
reset='\e[0m'
banner_messsage='POST MERGE HOOK'
banner_underline="$(printf %40s '' | sed 's/ /─/g')"
printf "%b\n%s\n%s\n%b" "$blue" "$banner_messsage" "$banner_underline" "$reset"
printf "Checking to see if any actions should be taken as a result of the merge:\n\n"

# NOTE: This should be the first check made because if the version for a tool changes to a version we do not have,
# that tool will error out when you call it. This could be an issue because some of the checks below may depend on
# these tools.
tool_versions='asdf/tool-versions'
if has_changes "$tool_versions"; then
  if confirm "The asdf tool version file has changed, would you like asdf to update from it?"; then
    suppress_error asdf install
  fi
fi

if has_added_file || has_deleted_file; then
  if confirm 'A file was added and/or deleted, would you like dotbot to relink?'; then
    suppress_error ./install/install --only clean link
  fi
fi

fish_plugins='fish/fish_plugins'
if has_changes "$fish_plugins"; then
  if confirm "The fish plugin file has changed, would you like fisher to update from it?"; then
    suppress_error fish -c 'source ~/.config/fish/functions/fisher.fish; fisher update'
  fi
fi

brewfile='brew/Brewfile'
if has_changes "$brewfile" && ! chronic brew bundle check --file "$brewfile" >/dev/null; then
  if confirm "You are missing dependencies specified in your Brewfile, would you like to install them?"; then
    suppress_error brew bundle install --file "$brewfile"
  fi
fi

vim_plug_snapshot='neovim/vim-plug-snapshot.vim'
if has_changes "$vim_plug_snapshot"; then
  if confirm "The neovim plugin snapshot has changed, would you like neovim to update from it?"; then
    suppress_error nvim -c 'autocmd VimEnter * PlugRestore'
  fi
fi

pipx_packages='pipx/pipx-packages'
if has_changes "$pipx_packages"; then
  if confirm "The pipx packages file has changed, would you like pipx to update from it?"; then
    suppress_error xargs -I PACKAGE pipx install PACKAGE < "$pipx_packages"
  fi
fi

bat_theme_file_pattern='bat/.*\.tmTheme$'
if has_changes "$bat_theme_file_pattern" || has_changes "$bat_theme_file_pattern"; then
  if confirm "A bat theme has changed, would you like to rebuild the bat cache?"; then
    suppress_error bat cache --build
  fi
fi

if has_changes 'watchman/watchman.json'; then
  if confirm "The watchman configuration has changed, would you like to reinstall it (you may need to restart watchman for the changes to take effect)?"; then
    suppress_error fish watchman/install.fish
  fi
fi

if has_changes 'fontconfig/local.conf' || has_changes 'fontconfig/10-nerd-font-symbols.conf'; then
  if confirm "The fontconfig configuration has changed, would you like to reinstall it (you may need to restart any application reading from fontconfig for the changes to take effect)?"; then
    suppress_error fish fontconfig/install.fish
  fi
fi

if has_changes 'bash/profile'; then
  echo "The bash profile has changed. To apply these changes you can log out. Press enter to continue (This will not log you out)"

  # To hide any keys the user may press before enter I disable echo. After prompting them, I re-enable it.
  stty_original="$(stty -g)"
  stty -echo
  # I don't care if read mangles backslashes since I'm not using the input anyway.
  # shellcheck disable=2162
  read _unused
  stty "$stty_original"
fi
