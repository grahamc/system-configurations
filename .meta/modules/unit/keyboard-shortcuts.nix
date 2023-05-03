{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      makeSymlinkToRepo
      runAfterWriteBoundary
      ;
    inherit (specialArgs) isGui;
    inherit (pkgs.stdenv) isLinux;
  in lib.mkIf (isLinux && isGui) {
    xdg.configFile = {
      "autokey/data".source = makeSymlinkToRepo "autokey/data";
    };

    home.activation.gnomeXkbSetup = runAfterWriteBoundary
      ''
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"
      '';
  }

