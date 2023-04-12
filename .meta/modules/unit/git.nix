{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeSymlinkToRepo
      makeSymlinksToTopLevelFilesInRepo
      ;
    gitExecutables = makeSymlinksToTopLevelFilesInRepo ".local/bin" "git/subcommands";
  in
    {
      home.packages = with pkgs; [
        git
        delta
        gitui
      ];

      home.file = {
        ".gitconfig".source = makeSymlinkToRepo "git/gitconfig";
        ".local/bin/delta-with-fallback-to-less".source = makeSymlinkToRepo "git/delta-with-fallback-to-less";
      } // gitExecutables;

      xdg.configFile = {
        "gitui/theme.ron".source = makeSymlinkToRepo "git/gitui/theme.ron";
      };
    }
