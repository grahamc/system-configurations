{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlink
      ;
  in
    {
      xdg.configFile = {
        "nix/nix.conf".source = makeOutOfStoreSymlink "nix/nix.conf";
        "fish/conf.d/nix-fzf.fish".source = makeOutOfStoreSymlink "nix/fzf.fish";
      };

      home.packages = with pkgs; [
        any-nix-shell
        comma
        nix-tree
      ];
    }
