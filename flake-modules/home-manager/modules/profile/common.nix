{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (specialArgs) repositoryDirectory self;
  in
    {
      imports = [
        ../login-shell.nix
        ../fish.nix
        ../nix.nix
        ../neovim.nix
        ../general.nix
        ../utility/vim-plug.nix
        ../utility/repository/symlink.nix
        ../utility/repository/repository.nix
        ../home-manager.nix
        ../fonts.nix
        ../keyboard-shortcuts.nix
        ../wezterm.nix
        ../tmux.nix
      ];

      repository.directory = repositoryDirectory;
      repository.directoryPath = self.outPath;
      repository.symlink.baseDirectory = "${repositoryDirectory}/dotfiles";

      # When switching generations, stop obsolete services and start ones that are wanted by active units.
      systemd.user.startServices = "sd-switch";
    }
