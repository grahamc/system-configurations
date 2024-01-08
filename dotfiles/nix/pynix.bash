#!/usr/bin/env bash

# Lets me starts a nix shell with python and the specified python packages.
# Example: `pynix requests marshmallow`

packages="$(printf "%s\n" "$@" | xargs -I PACKAGE printf "python3Packages.PACKAGE ")"
eval ".any-nix-shell-wrapper fish -p $packages"
