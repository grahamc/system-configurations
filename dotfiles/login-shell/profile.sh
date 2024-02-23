# shellcheck shell=sh

# Homebrew
if uname | grep -q Darwin; then
  brew="/usr/local/bin/brew"
  if [ -x "$brew" ]; then
    eval "$("$brew" shellenv sh)"
  fi
fi

# nix
#
# For non-NixOS linux distributions
# see: https://nixos.wiki/wiki/Locales
#
# TODO: See if Nix should do this as part of the script below.
if uname | grep -q Linux; then
  export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
fi
# TODO: I have to configure the Determinate Systems Nix installer to add configs for all shells not
# just the one I run the installer command in. This way all shells with have Nix set up properly. I
# also need to make sure fish picks up the config because based on this issue dont think it will:
# https://github.com/DeterminateSystems/nix-installer/issues/576
# Until I do the above, I'll manually source the config.
nix_daemon_script='/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
if [ -e "$nix_daemon_script" ]; then
  # shellcheck source=/dev/null
  . "$nix_daemon_script"
fi

# Not sure how to have nix-darwin do this for me so I hardcoded it.
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
