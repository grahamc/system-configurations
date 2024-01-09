{ lib, pkgs, specialArgs, ... }:
  let
    inherit (specialArgs) isGui;
    inherit (pkgs.stdenv) isLinux;
  in lib.mkIf (isLinux && isGui) {
    repository.symlink.xdg.executable = {
      "night-theme-switcher-fix".source = "gnome/night-theme-switcher-fix.sh";
    };

    repository.symlink.xdg.configFile = {
      "autostart/theme-sync.desktop".source = "gnome/theme-sync.desktop";
    };
  }
