#!/bin/sh
# shellcheck shell=sh

set -o errexit
set -o nounset

# The RemoteCommand is pretty long so I put it into a separate file and read it into a string here.
newline='
'
script_string=
while IFS= read -r line; do
    script_string="$script_string$line$newline"
done < "$HOME/.config/ssh/start-my-shell.sh"
if [ "$line" ]; then
    script_string="$script_string$line"
fi

ssh -o RequestTTY=yes -o RemoteCommand="$script_string" "$@"
