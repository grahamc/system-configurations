#!/bin/sh

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

if ! command -v nix >/dev/null 2>&1; then
  curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
fi

# Setup nix
#
# DUPLICATE: nix-setup
. "$HOME/.nix-profile/etc/profile.d/nix.sh"

xargs -I PACKAGE nix-env -i PACKAGE < ./nix/nix-packages.txt
