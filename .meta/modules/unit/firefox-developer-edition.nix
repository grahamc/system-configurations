{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlink
      ;
    inherit (specialArgs) isGui;
    inherit (pkgs.stdenv) isLinux;
  in lib.mkIf (isGui && isLinux) {
    xdg.dataFile = {
      "applications/my-firefox.desktop".source = makeOutOfStoreSymlink "firefox-developer-edition/my-firefox.desktop";
    };

    home.file.".local/bin/my-firefox".source = makeOutOfStoreSymlink "firefox-developer-edition/my-firefox";
  }
