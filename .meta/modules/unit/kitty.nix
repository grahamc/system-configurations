{ config, lib, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeSymlinkToRepo
      runAfterLinkGeneration
      ;
    inherit (specialArgs) isGui;
    currentTheme = "${config.xdg.configHome}/kitty/current-theme.conf";
  in lib.mkIf isGui {
    xdg.configFile = {
      "kitty/kitty.conf".source = makeSymlinkToRepo "kitty/kitty.conf";
      "kitty/day-theme.conf".source = makeSymlinkToRepo "kitty/day-theme.conf";
      "kitty/night-theme.conf".source = makeSymlinkToRepo "kitty/night-theme.conf";
    };

    home.activation.kittySetup = runAfterLinkGeneration ''
      if [ ! -f ${currentTheme} ]; then
        ln --symbolic --relative ./night-theme.conf ${currentTheme}
      fi
    '';
  }
