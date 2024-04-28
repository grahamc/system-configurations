# shellcheck shell=sh

# Homebrew
#
# TODO: Homebrew should be doing this
if uname | grep -q Darwin; then
  brew="/usr/local/bin/brew"
  if [ -x "$brew" ]; then
    eval "$("$brew" shellenv sh)"
  fi
fi

# For non-NixOS linux distributions
# see: https://nixos.wiki/wiki/Locales
#
# TODO: See if Nix should do this as part of its setup script
if uname | grep -q Linux; then
  export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
fi

# TODO: Not sure how to have nix-darwin do this for me so I hardcoded it. I'd
# probably have to add something to my darwin config that does what Determinate
# Systems does:
# https://determinate.systems/posts/nix-survival-mode-on-macos/
nix_darwin_bin='/run/current-system/sw/bin'
if [ -d "$nix_darwin_bin" ] && uname | grep -q Darwin; then
  export PATH="$nix_darwin_bin:$PATH"
fi

# This is where user-specific executables should go, per the XDG Base Directory
# spec [1]. While the OS is responsible for adding this to the PATH, there are
# two reasons why I'm doing it:
#
# 1. macOS is not compliant with the spec
#
# 2. I want the executables stored here to be on the PATH before all others
# since I keep wrappers for other programs in here.
#
# [1]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
PATH="$HOME/.local/bin:$PATH"
