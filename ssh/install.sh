#!/bin/sh

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

# Generate an ssh key pair if there aren't any existing keys.
SSH_KEY_DIRECTORY="$HOME/.ssh"
# We know there aren't keys if the key directory doesn't exist or it's empty.
if ! [ -d "$SSH_KEY_DIRECTORY" ] || [ -z "$(ls -A "$SSH_KEY_DIRECTORY")" ]; then
  ssh-keygen -t ed25519 -C "hi@bigo.lu"
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519
fi
