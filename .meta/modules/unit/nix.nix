{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeSymlinkToRepo
      ;
  in
    {
      xdg.configFile = {
        "nix/nix.conf".source = makeSymlinkToRepo "nix/nix.conf";
        "fish/conf.d/nix-fzf.fish".source = makeSymlinkToRepo "nix/fzf.fish";
      };

      home.packages = with pkgs; [
        any-nix-shell
        comma
        nix-tree
      ];
    }
