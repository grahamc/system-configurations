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
