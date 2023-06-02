# This module has the configuration that I always want applied.
{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (specialArgs) repositoryDirectory flakeInputs;
    inherit (lib.attrsets) optionalAttrs;
    inherit (pkgs.stdenv) isLinux;
  in
    {
      imports = [
        ../login-shell.nix
        ../fish.nix
        ../nix.nix
        ../neovim.nix
        ../general.nix
        ../utility/vim-plug.nix
        ../utility/repository
        ../home-manager.nix
        ../fonts.nix
        ../keyboard-shortcuts.nix
        ../wezterm.nix
        ../tmux.nix
      ];

      repository.directory = repositoryDirectory;
      repository.directoryPath = flakeInputs.self.outPath;
      repository.symlink.baseDirectory = "${repositoryDirectory}/dotfiles";

      # When switching generations, stop obsolete services and start ones that are wanted by active units.
      systemd = optionalAttrs isLinux {
        user.startServices = "sd-switch";
      };
    }
