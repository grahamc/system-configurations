{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeSymlinkToRepo
      ;
    inherit (lib.lists) optionals;
    inherit (pkgs.stdenv) isLinux;
  in
    {
      imports = [
        ../unit/bat.nix
        ../unit/git.nix
        ../unit/tmux.nix
        ../unit/kitty.nix
        ../unit/wezterm.nix
        ../unit/fbterm.nix
      ];

      home.packages = with pkgs; [
        pipr
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
      ] ++ optionals isLinux [
        trash-cli
      ];

      home.file = {
        # less
        ".lesskey".source = makeSymlinkToRepo "less/lesskey";

        # ripgrep
        ".ripgreprc".source = makeSymlinkToRepo "ripgrep/ripgreprc";

        # for any searchers e.g. ripgrep
        ".ignore".source = makeSymlinkToRepo "search/ignore";
      };

      xdg.configFile = {
        # lsd
        "lsd".source = makeSymlinkToRepo "lsd";

        # pipr
        "pipr/pipr.toml".source = makeSymlinkToRepo "pipr/pipr.toml";

        # viddy
        "viddy.toml".source = makeSymlinkToRepo "viddy/viddy.toml";

        # watchman
        "watchman/watchman.json".source = makeSymlinkToRepo "watchman/watchman.json";
      };
    }
