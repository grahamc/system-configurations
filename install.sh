#!/bin/env sh

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

git clone git@github.com:bigolu/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# I only have a login shell profile for bash.
if [ "$(basename "$SHELL")" != 'bash' ]; then
  echo 'Aborting since your default shell is not supported.' >&2
  exit 1
fi

# Do the linking now, so that the login shell profile gets linked.
if ! SHELL='sh' ./install/install --only link; then
  echo 'Aborting since the linking was not successful. Please address any issues and rerun this script.' >&2
  exit 1
fi

# Do a full install.
#
# Use a login shell so that it loads the newly linked login shell profile. This is done so that
# the packages from tools like homebrew and nix are available as soon as we install them,
# since the login shell profile adds their install paths to $PATH.
#
# I'm excluding the link directive since we did it before this.
"$SHELL" -l -c 'env SHELL=sh ./install/install --except link'

printf 'Finished!\n\nNOTE: The current login session doesn'\''t have the settings in the newly linked login shell profile so you should relogin to apply those settings. Otherwise, you'\''ll have issues like not being able to use the tools installed by homebrew, nix, etc.\n'
