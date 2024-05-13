#!/usr/bin/env bash

# For non-NixOS linux distributions
# see: https://nixos.wiki/wiki/Locales
#
# This script assumes bash is the default shell
#
# TODO: See if Nix should do this as part of its setup script

printf '\n%s\n' 'export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive' |
  sudo tee -a '/etc/profile' >/dev/null
