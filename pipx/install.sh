#!/bin/sh

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

xargs -I PACKAGE pipx install PACKAGE < "pipx/pipx-packages"
