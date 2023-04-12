{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeSymlinkToRepo
      ;
  in
    {
      home.packages = with pkgs; [
        direnv
      ];

      xdg.configFile = {
        "direnv/direnv.toml".source = makeSymlinkToRepo "direnv/direnv.toml";
      };
    }
