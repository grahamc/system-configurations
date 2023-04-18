{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeSymlinkToRepo
      ;
  in
    {
      xdg.configFile = {
        "nix/nix.conf".source = makeSymlinkToRepo "nix/nix.conf";
        "fish/conf.d/nix-fzf.fish".source = makeSymlinkToRepo "nix/fzf.fish";
      };

      home.packages = with pkgs; [
        any-nix-shell
        comma
        nix-tree
      ];

      home.file = {
        ".local/bin/manix" = {
          text = ''
            #!/bin/bash

            PATH="${pkgs.manix}/bin:$PATH"

            manix "" | grep '^# ' | sed 's/^# \(.*\) (.*/\1/;s/ (.*//;s/^# //' | fzf --preview="manix '{}'" | xargs manix
          '';
          executable = true;
        };
      };
    }
