{ lib, pkgs, specialArgs, ... }:
  let
    inherit (lib.lists) optionals;
    inherit (pkgs.stdenv) isLinux isDarwin;
    inherit (specialArgs) isGui;
    inherit (lib.attrsets) optionalAttrs;
  in
    {
      imports = [
        ../bat.nix
        ../git.nix
        ../fzf.nix
        ../direnv.nix
      ];

      home.packages =
        let
          toyboxPartial =
            let
              programsToKeep = [
                "toybox"
                "tar"
                "hostname"
              ] ++ optionals isLinux [
                "clear"
              ];
              findFilters = builtins.map (program: "! -name '${program}'") programsToKeep;
              findFiltersAsString = lib.strings.concatStringsSep " " findFilters;
            in
              pkgs.symlinkJoin {
                name = "toybox-partial";
                paths = [pkgs.toybox];
                buildInputs = [pkgs.makeWrapper];
                # toybox is a multi-call binary so we are going to delete everything besides the toybox executable and
                # the programs I need which are just symlinks to it
                postBuild = ''
                  cd $out
                  find . ${findFiltersAsString} -type f,l -exec rm -f {} +
                '';
              };
        in
          with pkgs; [
            doggo
            duf
            fd
            gping
            jq
            lsd
            moreutils
            xdgWrappers.ripgrep
            tealdeer
            viddy
            zoxide
            file
            chase
            gnugrep
            broot
            yash
            hyperfine
            gzip
            wget
            which
            atuin
            toyboxPartial
            # Useful for commands that don't work quite the same way between macOS and Linux
            coreutils-full
            # Though less is on most machines by default, I added it here because I need a relatively recent version (600)
            # since that's when they added support for XDG Base Directories.
            less
            # This wasn't in a docker container
            gnused
            # for xargs
            findutils
            # for ps
            procps
            ast-grep
          ] ++ optionals isLinux [
            trashy
            pipr
            catp
            # for pstree
            psmisc
          ] ++ optionals isDarwin [
            pstree
            # macOS comes with a very old version of ncurses that doesn't have a terminfo entry for tmux, tmux-256color
            ncurses
          ];

      xdg = {
        configFile = {
          "fish/conf.d/zoxide.fish".source = ''${
            pkgs.runCommand "zoxide-config.fish" {} "${pkgs.zoxide}/bin/zoxide init --no-cmd fish > $out"
          }'';

          "fish/conf.d/atuin.fish".source = ''${
            pkgs.runCommand "atuin-config.fish" { nativeBuildInputs = [ pkgs.atuin ]; }
            "atuin init fish --disable-up-arrow --disable-ctrl-r > $out"
          }'';

          # Taken from home-manager: https://github.com/nix-community/home-manager/blob/47c2adc6b31e9cff335010f570814e44418e2b3e/modules/programs/broot.nix#L151
          # I'm doing this because home-manager was bringing in the broot source code as a dependency.
          # Dummy file to prevent broot from trying to reinstall itself
          "broot" = {
            source = pkgs.writeTextDir "launcher/installed-v1" "";
            recursive = true;
          };

          "fish/conf.d/broot.fish".source = ''${
            pkgs.runCommand "broot.fish" { nativeBuildInputs = [ pkgs.broot ]; }
            "broot --print-shell-function fish > $out"
          }'';
        };

        dataFile = {
          "fish/vendor_completions.d/atuin.fish".source = "${pkgs.atuin}/share/fish/vendor_completions.d/atuin.fish";
        };
      };

      repository.symlink = {
        home.file = {
          ".ignore".source = "search/ignore";
        };

        xdg = {
          executable = {
            "myssh".source = "ssh/myssh.sh";
          };

          configFile = {
            "lsd".source = "lsd";
            "viddy.toml".source = "viddy/viddy.toml";
            "watchman/watchman.json".source = "watchman/watchman.json";
            "lesskey".source = "less/lesskey";
            "ripgrep/ripgreprc".source = "ripgrep/ripgreprc";
            "ssh/start-my-shell.sh".source = "ssh/start-my-shell.sh";
            "broot/conf.hjson".source = "broot/conf.hjson";
            "atuin/config.toml".source = "atuin/config.toml";
          } // optionalAttrs isLinux {
            "pipr/pipr.toml".source = "pipr/pipr.toml";
            "fish/conf.d/pipr.fish".source = "pipr/pipr.fish";
          } // optionalAttrs isGui {
            "wezterm/wezterm.lua".source = "wezterm/wezterm.lua";
          };
        };
      };
    }
