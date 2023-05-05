{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (specialArgs) isGui;
    inherit (pkgs.stdenv) isLinux;
  in lib.mkIf (isLinux && isGui) {
    repository.symlink.xdg.configFile = {
      "fontconfig/fonts.conf".source = "fontconfig/local.conf";
      "fontconfig/conf.d/10-nerd-font-symbols.conf".source = "fontconfig/10-nerd-font-symbols.conf";
    };
  }

