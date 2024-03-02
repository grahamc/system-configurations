#!/usr/bin/env sh
# shellcheck shell=sh

if uname | grep -q Darwin; then
  shell="$(dscl . -read ~/ UserShell | sed 's/UserShell: //')"
else
  shell="$(getent passwd "$LOGNAME" | cut -d: -f7)"
fi

if [ ! -x "$shell" ]; then
  echo 'Error: Unable to find default shell, defaulting to bash or sh, whichever is found first' >&2
  shell="$(command -v bash || command -v sh)"
fi

exec "$shell" "$@"
