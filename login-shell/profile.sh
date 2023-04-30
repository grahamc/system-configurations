# shellcheck shell=sh

# Setup nix
_nix_profile_setup_script="$HOME/.nix-profile/etc/profile.d/nix.sh"
if [ -e "$_nix_profile_setup_script" ]; then
  . "$_nix_profile_setup_script"
fi
export LOCALE_ARCHIVE="$HOME/.nix-profile/lib/locale/locale-archive"

# I want to keep a user-specific catalog so that I can manage it with Nix Home Manager
export XML_CATALOG_FILES="/etc/xml/catalog $HOME/.local/share/xml/catalog"

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
