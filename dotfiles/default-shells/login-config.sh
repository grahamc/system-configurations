# shellcheck shell=sh

kernel_name="$(uname)"

if [ "$kernel_name" = Darwin ]; then
  # TODO: Homebrew should be doing this
  eval "$(/usr/local/bin/brew shellenv sh)"

  # TODO: Not sure how to have nix-darwin do this for me so I hardcoded it. I'd
  # probably have to add something to my darwin config that does what Determinate
  # Systems does:
  # https://determinate.systems/posts/nix-survival-mode-on-macos/
  export PATH="/run/current-system/sw/bin:$PATH"
fi

if [ "$kernel_name" = Linux ]; then
  # For non-NixOS linux distributions
  # see: https://nixos.wiki/wiki/Locales
  #
  # TODO: See if Nix should do this as part of its setup script
  export LOCALE_ARCHIVE=/usr/lib/locale/locale-archive
fi
