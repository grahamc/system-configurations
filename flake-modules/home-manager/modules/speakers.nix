{ config, lib, pkgs, specialArgs, ... }:
  lib.attrsets.optionalAttrs specialArgs.isGui {
    repository.symlink.home.file = lib.attrsets.optionalAttrs pkgs.stdenv.isDarwin {
      ".hammerspoon/Spoons/Speakers.spoon".source = "smart_plug/mac_os/Speakers.spoon";
    };

    home.packages = [
      specialArgs.flakeInputs.speakers.packages.${pkgs.system}.default
    ];
  }
