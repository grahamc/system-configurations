#!/usr/bin/env sh
# shellcheck shell=sh

if [ -n "$BIGOLU_PORTABLE_HOME_SHELL" ]; then
  shell="$BIGOLU_PORTABLE_HOME_SHELL"
  # Normally I set SHELL in the profile for the default shell, but for portable home I don't have
  # my default shell profile so instead I go straight into my shell
  export SHELL="$shell"
elif uname | grep -q Darwin; then
  shell="$(dscl . -read ~/ UserShell | sed 's/UserShell: //')"
else
  shell="$(getent passwd "$LOGNAME" | cut -d: -f7)"
fi

if [ ! -x "$shell" ]; then
  echo 'Error: Unable to find default shell, defaulting to bash or sh, whichever is found first' >&2
  shell="$(command -v bash || command -v sh)"
fi

exec "$shell" "$@"
