#!/usr/bin/env bash

# exit the script if any command returns a non-zero exit code
set -e

# source:
# https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself
script_directory="$(
  cd -- "$(dirname "$0")" >/dev/null 2>&1
  pwd -P
)"

sudo install --compare --owner=root --group=root --mode='u=rwx,g=r,o=r' -D --verbose --no-target-directory "$script_directory/turn-off-speakers" /etc/NetworkManager/dispatcher.d/pre-down.d/turn-off-speakers
sudo install --compare --owner=root --group=root --mode='u=rwx,g=r,o=r' -D --verbose --no-target-directory "$script_directory/smart-plug.service" /etc/systemd/system/smart-plug.service
speaker_path='/opt/speaker'
sudo mkdir -p "$speaker_path"
speakerctl_name='speakerctl'
sudo install --compare --owner=root --group=root --mode='u=rwx,g=r,o=r' -D --verbose --no-target-directory "$(which "$speakerctl_name")" "$speaker_path/$speakerctl_name"
sudo systemctl enable smart-plug.service
sudo systemctl start smart-plug.service
