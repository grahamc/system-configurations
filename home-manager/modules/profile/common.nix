{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (specialArgs) nix-index-database;
  in
    {
      imports = [
        ../login-shell.nix
        ../fish.nix
        ../nix.nix
        ../neovim.nix
        ../general.nix
        nix-index-database.hmModules.nix-index
        ../utility/vim-plug.nix
        ../utility/repository/repository.nix
        ../home-manager.nix
      ];

      repository.path = ".dotfiles";

      repository.git.onChange = [
        {
          # This should be the first check since other checks might depend on new files
          # being linked, or removed files being unlinked, in order to work. For example, if a new
          # bat theme is added, the theme needs to be linked before we can rebuild the bat cache.
          priority = 100;
          patterns = {
            added = ["*"];
            deleted = ["*"];
            modified = ["\\.nix$" "flake\\.lock"];
          };
          action = ''
            home-manager-switch
          '';
        }
      ];

      # When switching generations, stop obsolete services and start ones that are wanted by active units.
      systemd.user.startServices = "sd-switch";
    }
