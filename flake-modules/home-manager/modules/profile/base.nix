# This module has the configuration that I always want applied.
{...}: {
  imports = [
    ../default-shells.nix
    ../fish.nix
    ../nix.nix
    ../neovim.nix
    ../general.nix
    ../utility
    ../home-manager.nix
    ../fonts.nix
    ../keyboard-shortcuts.nix
    ../tmux.nix
  ];
}
