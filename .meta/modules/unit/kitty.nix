{ config, lib, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlink
      runAfterLinkGeneration
      ;
    inherit (specialArgs) isGui;
    currentTheme = "${config.xdg.configHome}/kitty/current-theme.conf";
  in lib.mkIf isGui {
    xdg.configFile = {
      "kitty/kitty.conf".source = makeOutOfStoreSymlink "kitty/kitty.conf";
      "kitty/day-theme.conf".source = makeOutOfStoreSymlink "kitty/day-theme.conf";
      "kitty/night-theme.conf".source = makeOutOfStoreSymlink "kitty/night-theme.conf";
    };

    home.file = {
      ".local/bin/reload-kitty".source = makeOutOfStoreSymlink "kitty/reload-kitty";
    };

    home.activation.kittySetup = runAfterLinkGeneration ''
      if [ ! -f ${currentTheme} ]; then
        ln --symbolic --relative ./night-theme.conf ${currentTheme}
      fi
    '';
  }
