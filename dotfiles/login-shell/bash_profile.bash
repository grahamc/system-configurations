# shellcheck shell=bash

if [ -f ~/.profile ]; then
  set -o posix
  # shellcheck source=/dev/null
  . ~/.profile
  set +o posix
fi

if [ -f ~/.bashrc ]; then
  # Load bashrc if this shell is interactive
  if [[ $- == *i* ]]; then
    # shellcheck source=/dev/null
    . ~/.bashrc
  fi
fi
