#!/bin/env sh

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

filename="index-$(uname -m)-$(uname | tr '[:upper:]' '[:lower:]')"
mkdir -p ~/.cache/nix-index && cd ~/.cache/nix-index
# -N will only download a new version if there is an update.
wget -q -N "https://github.com/Mic92/nix-index-database/releases/latest/download/$filename"
ln -f "$filename" files
