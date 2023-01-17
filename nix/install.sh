#!/bin/sh

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

if ! command -v nix >/dev/null 2>&1; then
  if ! curl -L https://nixos.org/nix/install | sh -s -- --no-daemon; then
    echo 'Failed to install nix, aborting the rest of the nix setup.' >&2
    exit 1
  fi

  if ! command -v nix >/dev/null 2>&1; then
    echo 'Nix was installed, but it is still not on the path. Please look into this and try again.' >&2
    exit 1
  fi
fi

xargs -I PACKAGE nix-env -i PACKAGE < ./nix/nix-packages.txt
