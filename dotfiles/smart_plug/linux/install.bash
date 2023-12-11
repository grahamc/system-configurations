#!/usr/bin/env bash

# exit the script if any command returns a non-zero exit code
set -e

sudo install --compare --owner=root --group=root --mode='u=rwx,g=r,o=r' -D --verbose --no-target-directory ./turn-off-speakers /etc/NetworkManager/dispatcher.d/pre-down.d/turn-off-speakers
sudo install --compare --owner=root --group=root --mode='u=rwx,g=r,o=r' -D --verbose --no-target-directory ./smart-plug-daemon.service /etc/systemd/system/smart-plug-daemon.service
speaker_path='/opt/speaker'
sudo mkdir -p "$speaker_path"
speakerctl_name='speakerctl'
sudo install --compare --owner=root --group=root --mode='u=rwx,g=r,o=r' -D --verbose --no-target-directory "$(which "$speakerctl_name")" "$speaker_path/$speakerctl_name"
sudo systemctl enable smart-plug-daemon.service
sudo systemctl start smart-plug-daemon.service
