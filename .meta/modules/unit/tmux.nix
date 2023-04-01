{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlink
      ;
  in
    {
      home.packages = with pkgs; [
        tmux
      ];

      home.file = {
        ".tmux.conf".source = makeOutOfStoreSymlink "tmux/tmux.conf";
        ".local/bin/tmux-nest".source = makeOutOfStoreSymlink "tmux/tmux-nest";
        ".local/bin/tmux-click-url.py".source = makeOutOfStoreSymlink "tmux/tmux-click-url.py";
      };
    }
