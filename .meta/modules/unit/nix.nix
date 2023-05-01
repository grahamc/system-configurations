{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      makeSymlinkToRepo
      ;
    inherit (lib.lists) optionals;
    inherit (pkgs.stdenv) isLinux;
  in
    {
      xdg.configFile = {
        "nix/nix.conf".source = makeSymlinkToRepo "nix/nix.conf";
        "nix/repl-startup.nix".source = makeSymlinkToRepo "nix/repl-startup.nix";
        "fish/conf.d/nix.fish".source = makeSymlinkToRepo "nix/nix.fish";
      };

      home.packages = with pkgs; [
        any-nix-shell
        comma
        nix-tree
      ] ++ optionals isLinux [
        glibcLocales
      ];

      home.file = {
        ".local/bin/manix" = {
          text = ''
            #!${pkgs.bash}/bin/bash

            PATH="${pkgs.manix}/bin:$PATH"

            # There's a bug in manix and certain options aren't being generated so I'm suppressing the errors printed
            # issue: https://github.com/mlvzk/manix/issues/24
            manix "" 2>/dev/null | grep '^# ' | sed 's/^# \(.*\) (.*/\1/;s/ (.*//;s/^# //' | fzf --preview="manix '{}' 2>/dev/null" | xargs manix 2>/dev/null
          '';
          executable = true;
        };
        ".local/bin/nix".source = makeSymlinkToRepo "nix/nix-repl-wrapper.fish";
      };
    }
