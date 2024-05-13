# This module has the configuration that I always want applied.
_: {
  imports = [
    ../homebrew.nix
    ../nix.nix
    ../nix-darwin.nix
    ../system-settings.nix
    ../skhd.nix
    ../yabai.nix
    ../utilities.nix
  ];

  programs.bash.enable = false;
}
