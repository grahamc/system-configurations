# shellcheck shell=sh

# Setup nix
# For the Determinate Systems multi-user installer. The installer receipt says it add this to /etc/zshrc, but I don't
# see it so it never gets called on macOS.
_nix_profile_multi_user_setup_script="/etc/bash.bashrc"
if [ -e "$_nix_profile_multi_user_setup_script" ]; then
  # The script is in bash so I'm sourcing it in a bash shell and having that shell print out its environment, one
  # variable per line, in the form `export NAME='value'`. This way I can just `eval` those export statements
  # in this shell.
  #
  # - I omit the SHLVL of the bash shell since I don't want the SHLVL in this shell to change.
  #
  # - The `-0` flag in env terminates each environment variable with a null byte, instead of a newline.
  # The `-z` in sed tells sed that its input is separated by null bytes and not newlines. With both of these, I
  # can distinguish between the end of an environment variable and a newline inside a variable. The `tr` command
  # removes the null bytes from sed's output.
  #
  # - Since I use single quotes to enclose the variable I have to do something about single quotes inside the
  # variable. The second sed command will replace those single quotes with `'"'"'`. An explanation of what that does
  # is here: https://stackoverflow.com/a/1250279. The groups of 3 backslashes are there to escape the double quotes
  # right after them.
  BASH_ENVIRONMENT="$(bash -c ". $_nix_profile_multi_user_setup_script; env -0 -u SHLVL | sed -z \"s/^/export /;s/'/'\\\"'\\\"'/g;s/=/='/;s/$/'\;\n/\" | tr -d '\000'")"
  eval "$BASH_ENVIRONMENT"
fi
# For non-NixOS linux distributions
# see: https://nixos.wiki/wiki/Locales
if uname | grep -q Linux; then
  export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
fi
# For single-user Nix. I don't think it left a setup script in any of the shells' vendor directories.
_nix_single_user="$HOME/.nix-profile/etc/profile.d/nix.sh"
if [ -e "$_nix_single_user" ]; then
  . "$_nix_single_user"
fi
# nix-darwin. Not sure how to have it configure this for me so I hardcoded it.
nix_darwin_bin='/run/current-system/sw/bin'
if [ -d "$nix_darwin_bin" ] && uname | grep -q Darwin; then
  export PATH="$nix_darwin_bin:$PATH"
fi
# nix-darwin manages brew so I'll turn off all the automatic management.
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

# Enable smooth scrolling in Firefox for Linux
if uname | grep -q Linux; then
  export MOZ_USE_XINPUT2=1
fi
