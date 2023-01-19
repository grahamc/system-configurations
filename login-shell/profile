# shellcheck shell=sh

# Setup brew
#
# DUPLICATE: brew-setup
brew_executable="/home/linuxbrew/.linuxbrew/bin/brew"
if [ -e "$brew_executable" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi


# Setup nix
#
# DUPLICATE: nix-setup
_nix_profile_setup_script="$HOME/.nix-profile/etc/profile.d/nix.sh"
if [ -e "$_nix_profile_setup_script" ]; then
  . "$_nix_profile_setup_script"
fi

# Setup asdf version manager
#
# DUPLICATE: asdf-setup
if command -v brew >/dev/null 2>&1; then
    _asdf_init_script="$(brew --prefix asdf)/libexec/asdf.sh"
    test -e "$_asdf_init_script" && . "$_asdf_init_script"
fi

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
