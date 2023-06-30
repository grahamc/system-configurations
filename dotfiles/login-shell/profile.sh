# shellcheck shell=sh

# Setup nix
# For non-NixOS linux distributions
# see: https://nixos.wiki/wiki/Locales
if uname | grep -q Linux; then
  export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
fi
# TODO: For the Determinate Systems multi-user installer. The installer adds a snippet to the shell profiles in /etc,
# but macOS overwrites the shell profiles during a system update.
# issues:
#   - https://github.com/NixOS/nix/issues/8385
#   - https://github.com/NixOS/nix/issues/3616
#   - https://github.com/NixOS/nix/issues/6117
nix_daemon_script='/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
if [ -e "$nix_daemon_script" ]; then
  # shellcheck source=/dev/null
  . "$nix_daemon_script"
fi
# nix-darwin. Not sure how to have it configure this for me so I hardcoded it.
nix_darwin_bin='/run/current-system/sw/bin'
if [ -d "$nix_darwin_bin" ] && uname | grep -q Darwin; then
  export PATH="$nix_darwin_bin:$PATH"
fi

# Homebrew
brew="/usr/local/bin/brew"
if [ -x "$brew" ]; then
  eval "$("$brew" shellenv sh)"
fi

# go
export GOPATH="$HOME/.local/share/go"
export PATH="$GOPATH/bin:$PATH"

# Adding this to the PATH since this is where user-specific executables should go, per the
# XDG Base Directory spec.
# More info: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
#
# NOTE: I keep this at the bottom so that my executables will be found before any others, allowing me to wrap
# other executables.
PATH="$HOME/.local/bin:$PATH"

# Enable smooth scrolling in Firefox for Linux
if uname | grep -q Linux; then
  export MOZ_USE_XINPUT2=1
fi
