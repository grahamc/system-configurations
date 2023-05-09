# Utilities for working with the repository that contains your Home Manager configuration.
{ config, lib, pkgs, ... }:
  let
    inherit (lib) types;
  in
    {
      imports = [
        ./git/git.nix
      ];

      options.repository = {
        directory = lib.mkOption {
          type = types.str;
          description = "Absolute path to the root of the repository.";
        };
      };
    }
