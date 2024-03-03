#!/usr/bin/env bash

# Exit the script if any command returns a non-zero exit code.
set -o errexit
# Exit the script if an undefined variable is referenced.
set -o nounset

sudo install --compare --backup --suffix=.bak --owner=root --group=root --mode='u=rwx,g=r,o=r' -D --verbose --no-target-directory ~/.dotfiles/dotfiles/nix/nix-fix/zz-nix-fix.fish /usr/share/fish/vendor_conf.d/zz-nix-fix.fish
