{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (specialArgs) isGui;
    inherit (pkgs.stdenv) isLinux;
  in lib.mkIf (isGui && isLinux) {
    repository.symlink.xdg.dataFile = {
      "applications/my-firefox.desktop".source = "firefox-developer-edition/my-firefox.desktop";
    };

    repository.symlink.home.file.".local/bin/my-firefox".source = "firefox-developer-edition/my-firefox";

    home.activation.firefoxDeveloperEditionSetup = lib.hm.dag.entryAfter
      # Must be after `linkGeneration` since that's when the desktop entry will be linked in.
      ["linkGeneration"]
      ''
        ${pkgs.xdg-utils}/bin/xdg-settings set default-web-browser my-firefox.desktop
      '';
  }
