{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (specialArgs) isGui;
    inherit (pkgs.stdenv) isLinux;
  in lib.mkIf (isLinux && isGui) {
    symlink.xdg.configFile = {
      "autokey/data".source = "autokey/data";
    };

    home.activation.gnomeXkbSetup = lib.hm.dag.entryAfter
      [ "writeBoundary" ]
      ''
      ${pkgs.glib}/bin/gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"
      '';
  }

