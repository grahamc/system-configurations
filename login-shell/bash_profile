# shellcheck shell=bash

if [ -f ~/.profile ]; then
    . ~/.profile
fi

if [ -f ~/.bashrc ]; then
    # Load bashrc if this shell is interactive
    if [[ $- == *i* ]]; then
      . ~/.bashrc
    fi
fi

