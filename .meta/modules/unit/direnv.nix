{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlink
      ;
  in
    {
      home.packages = with pkgs; [
        direnv
      ];

      xdg.configFile = {
        "direnv/direnv.toml".source = makeOutOfStoreSymlink "direnv/direnv.toml";
      };
    }
