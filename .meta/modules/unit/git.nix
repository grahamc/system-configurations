{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlink
      makeOutOfStoreSymlinksForTopLevelFiles
      ;
    gitExecutables = makeOutOfStoreSymlinksForTopLevelFiles ".local/bin" "git/subcommands";
  in
    {
      home.packages = with pkgs; [
        git
        delta
        gitui
      ];

      home.file = {
        ".gitconfig".source = makeOutOfStoreSymlink "git/gitconfig";
        ".local/bin/delta-with-fallback-to-less".source = makeOutOfStoreSymlink "git/delta-with-fallback-to-less";
      } // gitExecutables;

      xdg.configFile = {
        "gitui/theme.ron".source = makeOutOfStoreSymlink "git/gitui/theme.ron";
      };
    }
