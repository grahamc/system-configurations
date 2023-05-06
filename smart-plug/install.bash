#!/usr/bin/env bash

# exit the script if any command returns a non-zero exit code
set -e

sudo install --compare --backup --suffix=.bak --owner=root --group=root --mode='u=rwx,g=r,o=r' -D --verbose --no-target-directory ~/.dotfiles/smart-plug/wait-one-second /etc/NetworkManager/dispatcher.d/pre-down.d/wait-one-second
sudo install --compare --backup --suffix=.bak --owner=root --group=root --mode='u=rwx,g=r,o=r' -D --verbose --no-target-directory ~/.dotfiles/smart-plug/smart-plug-daemon.service /etc/systemd/system/smart-plug-daemon.service
sudo systemctl enable smart-plug-daemon.service
sudo systemctl start smart-plug-daemon.service
