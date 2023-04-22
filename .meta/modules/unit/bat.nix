{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      makeSymlinkToRepo
      runAfterLinkGeneration
      ;
  in
    {
      xdg.configFile = {
        "bat/config".source = makeSymlinkToRepo "bat/config";
        "bat/themes/base16-brighter.tmTheme".source = makeSymlinkToRepo "bat/base16-brighter.tmTheme";
      };

      home.packages = with pkgs; [
        bat
      ];

      home.activation.batSetup = runAfterLinkGeneration ''
        export PATH="${pkgs.bat}/bin:${pkgs.moreutils}/bin:$PATH"
        chronic bat cache --build
      '';
    }
