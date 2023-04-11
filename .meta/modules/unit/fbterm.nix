{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlink
      ;
    inherit (pkgs.stdenv) isLinux;
    inherit (specialArgs) isGui;
  in lib.mkIf (isLinux && isGui) {
    home.packages = with pkgs; [
      fbterm
    ];

    home.file = {
      ".fbtermrc".source = makeOutOfStoreSymlink "fbterm/fbtermrc";
    };
  }
