{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeSymlinkToRepo
      ;
  in
    {
      home.packages = with pkgs; [
        tmux
      ];

      home.file = {
        ".tmux.conf".source = makeSymlinkToRepo "tmux/tmux.conf";
        ".local/bin/tmux-nest".source = makeSymlinkToRepo "tmux/tmux-nest";
        ".local/bin/tmux-click-url.py".source = makeSymlinkToRepo "tmux/tmux-click-url.py";
      };
    }
