#!/usr/bin/env bash

# Exit the script if any command returns a non-zero exit code.
set -o errexit
# Exit the script if an undefined variable is referenced.
set -o nounset

sudo install --compare --backup --suffix=.bak --owner=root --group=root --mode='u=rwx,g=r,o=r' -D --verbose --no-target-directory ~/.dotfiles/dotfiles/nix/systemd-garbage-collection/nix-garbage-collection.service /etc/systemd/system/nix-garbage-collection.service
sudo install --compare --backup --suffix=.bak --owner=root --group=root --mode='u=rwx,g=r,o=r' -D --verbose --no-target-directory ~/.dotfiles/dotfiles/nix/systemd-garbage-collection/nix-garbage-collection.timer /etc/systemd/system/nix-garbage-collection.timer
sudo systemctl daemon-reload
sudo systemctl enable nix-garbage-collection.timer
sudo systemctl start nix-garbage-collection.timer
