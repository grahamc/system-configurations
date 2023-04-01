{ config, lib, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlink
      ;
    inherit (specialArgs) isGui;
  in lib.mkIf isGui {
    xdg.dataFile = {
      "applications/code.desktop".source = makeOutOfStoreSymlink "vscode/code.desktop";
    };

    home.file = {
      ".local/bin/code".source = makeOutOfStoreSymlink "vscode/code";
    };
  }
