# Utilities for working with the repository that contains your Home Manager configuration.
{ lib, ... }:
  let
    inherit (lib) types;
  in
    {
      imports = [
        ./git
        ./symlink.nix
      ];

      options.repository = {
        directory = lib.mkOption {
          type = types.str;
          description = "Absolute path to the root of the repository.";
        };
        directoryPath = lib.mkOption {
          type = types.path;
          description = "Same as directory, but with the type of the path builtin.";
        };
      };
    }
