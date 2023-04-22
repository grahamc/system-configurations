{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      makeSymlinkToRepo
      ;
    inherit (specialArgs) isGui;
    inherit (pkgs.stdenv) isLinux;
  in lib.mkIf (isGui && isLinux) {
    xdg.dataFile = {
      "applications/my-firefox.desktop".source = makeSymlinkToRepo "firefox-developer-edition/my-firefox.desktop";
    };

    home.file.".local/bin/my-firefox".source = makeSymlinkToRepo "firefox-developer-edition/my-firefox";
  }
