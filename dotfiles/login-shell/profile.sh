# shellcheck shell=sh

# Setup nix
# For the Determinate Systems multi-user installer. The installer receipt says it add this to /etc/zshrc, but I don't
# see it so it never gets called on macOS.
_nix_profile_multi_user_setup_script="/etc/bash.bashrc"
if [ -e "$_nix_profile_multi_user_setup_script" ]; then
  # The script is in bash so I'm sourcing it in a bash shell and having that shell print out its environment, one
  # variable per line, in the form `export NAME="value"`. This way I can just `eval` those export statements
  # in this shell.
  #
  # This will break if the environment variable value has newlines though. I omit the SHLVL of the bash shell since
  # I don't want the SHLVL in this shell to change.
  BASH_ENVIRONMENT="$(bash -c ". $_nix_profile_multi_user_setup_script; env -u SHLVL | sed 's/^/export /;s/=/=\"/;s/$/\"/'")"
  eval "$BASH_ENVIRONMENT"
fi
# For non-NixOS linux distributions
# see: https://nixos.wiki/wiki/Locales
if uname | grep -q Linux; then
  export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
fi
# nix-darwin. Not sure how to have it configure this for me so I hardcoded it.
export PATH="/run/current-system/sw/bin:$PATH"

# brew
export HOMEBREW_NO_INSTALL_UPGRADE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_AUTO_UPDATE=1

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

# switch to fbterm if we are running in a TTY
# [ "$TERM" = "linux" ] && [[ $- == *i* ]] && command -v fbterm >/dev/null 2>&1 && FBTERM=1 exec fbterm

# [ "$TERM" = "linux" ] && [[ $- == *i* ]] && export LC_ALL=en_US.UTF-8 && FBTERM=1 exec fbterm --font-size=20 -i fbterm_ucimf
