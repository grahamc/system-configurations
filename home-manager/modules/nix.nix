{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (lib.lists) optionals;
    inherit (pkgs.stdenv) isLinux;
  in
    {
      repository.symlink.xdg.configFile = {
        "nix/nix.conf".source = "nix/nix.conf";
        "nix/repl-startup.nix".source = "nix/repl-startup.nix";
        "fish/conf.d/nix.fish".source = "nix/nix.fish";
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
      };
      repository.symlink.home.file = {
        ".local/bin/nix".source = "nix/nix-repl-wrapper.fish";
      };
    }
