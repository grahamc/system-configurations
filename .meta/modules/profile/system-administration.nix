{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      makeSymlinkToRepo
      ;
    inherit (lib.lists) optionals;
    inherit (pkgs.stdenv) isLinux;
    inherit (lib.attrsets) optionalAttrs;
  in
    {
      imports = [
        ../unit/bat.nix
        ../unit/git.nix
        ../unit/tmux.nix
        ../unit/wezterm.nix
        ../unit/fbterm.nix
      ];

      home.packages = with pkgs; [
        timg
        autossh
        doggo
        duf
        fd
        fzf
        gping
        jq
        lsd
        moreutils
        ncdu
        ripgrep
        tealdeer
        tree
        viddy
        watchman
        zoxide
        file
        # This is on most machines by default, but not with the version I need. I need at least version 600 since
        # that's where they added support for XDG Base Directories.
        less
      ] ++ optionals isLinux [
        trash-cli
        pipr
      ];

      home.file = {
        # ripgrep
        ".ripgreprc".source = makeSymlinkToRepo "ripgrep/ripgreprc";

        # for any searchers e.g. ripgrep
        ".ignore".source = makeSymlinkToRepo "search/ignore";
      } // optionalAttrs isLinux {
        ".local/bin/pbcopy".source = makeSymlinkToRepo "general/executables/osc-copy";
        ".local/bin/pbpaste" = {
          text = ''
            #!${pkgs.fish}/bin/fish

            if type --query wl-paste
              wl-paste
            else if type --query xclip
              xclip -selection clipboard -out
            else
              echo "Error: Can't find a program to pasting clipboard contents" 1>/dev/stderr
            end
          '';
          executable = true;
        };
      };

      xdg.configFile = {
        # lsd
        "lsd".source = makeSymlinkToRepo "lsd";

        # viddy
        "viddy.toml".source = makeSymlinkToRepo "viddy/viddy.toml";

        # watchman
        "watchman/watchman.json".source = makeSymlinkToRepo "watchman/watchman.json";

        # less
        "lesskey".source = makeSymlinkToRepo "less/lesskey";
      } // optionalAttrs isLinux {
        # pipr
        "pipr/pipr.toml".source = makeSymlinkToRepo "pipr/pipr.toml";
      };
    }
