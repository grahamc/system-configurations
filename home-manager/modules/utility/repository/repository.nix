# Utilities for working with the repository that contains your Home Manager configuration.
{ config, lib, pkgs, ... }:
  let
    inherit (lib) types;
  in
    {
      imports = [
        ./symlink.nix
        ./git/git.nix
      ];

      options.repository = {
        path = lib.mkOption {
          type = types.str;
          example = ".dotfiles";
          description = "(relative to the home directory)";
        };
      };
    }
