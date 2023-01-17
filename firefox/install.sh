#!/bin/env sh

# shellcheck shell=sh

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

cd "$(mktemp --directory)"

curl --location "https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64&lang=en-US" \
  | tar --extract --verbose --preserve-permissions --bzip2

sudo mv firefox /opt/

ln -s /opt/firefox/firefox ~/.local/bin/firefox-developer-edition

xdg-settings set default-web-browser my-firefox.desktop
