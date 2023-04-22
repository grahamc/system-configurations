{ config, lib, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      makeSymlinkToRepo
      ;
    inherit (specialArgs) isGui;
  in lib.mkIf isGui {
    xdg.dataFile = {
      "applications/code.desktop".source = makeSymlinkToRepo "vscode/code.desktop";
    };

    home.file = {
      ".local/bin/code".source = makeSymlinkToRepo "vscode/code";
    };
  }
