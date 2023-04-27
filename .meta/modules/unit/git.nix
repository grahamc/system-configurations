{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      makeSymlinkToRepo
      makeSymlinksToTopLevelFilesInRepo
      ;
    gitExecutables = makeSymlinksToTopLevelFilesInRepo ".local/bin" "git/subcommands" ../../../git/subcommands;
  in
    {
      home.packages = with pkgs; [
        git
        delta
        gitui
      ];

      home.file = gitExecutables;

      xdg.configFile = {
        "gitui/theme.ron".source = makeSymlinkToRepo "git/gitui/theme.ron";
        "git/config".source = makeSymlinkToRepo "git/gitconfig";
      };
    }
