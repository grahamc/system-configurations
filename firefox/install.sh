#!/bin/env sh

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

# Install Firefox Developer Edition
if [ -d /opt/firefox ]; then
  echo 'Firefox is already installed, exiting.'
  exit
fi
cd "$(mktemp --directory)"
curl --location "https://download.mozilla.org/?product=firefox-devedition-latest-ssl&os=linux64&lang=en-US" \
  | tar --extract --verbose --preserve-permissions --bzip2
sudo mv firefox /opt/
FIREFOX_EXECUTABLE="$HOME/.local/bin/firefox-developer-edition"
if [ -f "$FIREFOX_EXECUTABLE" ]; then
  rm "$FIREFOX_EXECUTABLE"
fi
ln --force --symbolic /opt/firefox/firefox "$FIREFOX_EXECUTABLE"
xdg-settings set default-web-browser my-firefox.desktop
