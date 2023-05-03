{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      makeSymlinkToRepo
      ;
    inherit (specialArgs) isGui;
    inherit (pkgs.stdenv) isLinux;
  in lib.mkIf (isLinux && isGui) {
    home.file = {
      ".local/bin/night-theme-switcher-fix".source = makeSymlinkToRepo "gnome/night-theme-switcher-fix.sh";
    };

    xdg.configFile = {
      "autostart/theme-sync.desktop".source = makeSymlinkToRepo "gnome/theme-sync.desktop";
    };
  }
