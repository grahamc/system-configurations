# shellcheck shell=sh

# Homebrew
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

# TODO: Not sure how to have nix-darwin do this for me so I hardcoded it. I'd probably have to add
# something to my darwin config that does what Determinate Systems does:
# https://determinate.systems/posts/nix-survival-mode-on-macos/
nix_darwin_bin='/run/current-system/sw/bin'
if [ -d "$nix_darwin_bin" ] && uname | grep -q Darwin; then
  export PATH="$nix_darwin_bin:$PATH"
fi

# go
export GOPATH="$HOME/.local/share/go"
export PATH="$GOPATH/bin:$PATH"

# Setting this so python doesn't create `__pycache__` folders in the current directory whenever I
# run a script
export PYTHONDONTWRITEBYTECODE=1

# Enable smooth scrolling in Firefox for Linux
if uname | grep -q Linux; then
  export MOZ_USE_XINPUT2=1
fi

# Adding this to the PATH since this is where user-specific executables should go, per the XDG Base
# Directory spec. More info:
# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
#
# NOTE: I keep this at the bottom so that my executables will be found before any others, allowing
# me to wrap other executables.
PATH="$HOME/.local/bin:$PATH"
