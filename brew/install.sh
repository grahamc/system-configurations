#!/bin/sh

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

if ! command -v brew >/dev/null 2>&1; then
  if ! bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    echo 'Failed to install brew, aborting the rest of the brew setup.' >&2
    exit 1
  fi

  if ! command -v brew >/dev/null 2>&1; then
    echo 'Brew was installed, but it is still not on the path. Please look into this and try again.' >&2
    exit 1
  fi
fi

brew bundle install --no-upgrade --file ./brew/Brewfile
