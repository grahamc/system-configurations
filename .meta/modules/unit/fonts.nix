{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      makeSymlinkToRepo
      ;
    inherit (specialArgs) isGui;
    inherit (pkgs.stdenv) isLinux;
  in lib.mkIf (isLinux && isGui) {
    xdg.configFile = {
      "fontconfig/fonts.conf".source = makeSymlinkToRepo "fontconfig/local.conf";
      "fontconfig/conf.d/10-nerd-font-symbols.conf".source = makeSymlinkToRepo "fontconfig/10-nerd-font-symbols.conf";
    };
  }

