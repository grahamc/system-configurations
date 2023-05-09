{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (lib.lists) optionals;
    inherit (pkgs.stdenv) isLinux;
    inherit (specialArgs) nix-index-database;
  in
    {
      imports = [
        nix-index-database.hmModules.nix-index
      ];

      repository.symlink.xdg.configFile = {
        "nix/nix.conf".source = "nix/nix.conf";
        "nix/repl-startup.nix".source = "nix/repl-startup.nix";
        # I prefixed the name of this file with 'my-' because otherwise it would have the same name as the configuration
        # file that comes with Nix. This is a problem because if fish sees two config files with the same basename, only
        # one gets loaded: https://fishshell.com/docs/current/language.html#configuration-files.
        "fish/conf.d/my-nix.fish".source = "nix/nix.fish";
      };

      home.packages = with pkgs; [
        any-nix-shell
        nix-tree
        comma
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
