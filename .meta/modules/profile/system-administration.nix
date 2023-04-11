{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlink
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
      ] ++ optionals isLinux [
        trash-cli
      ];

      home.file = {
        # less
        ".lesskey".source = makeOutOfStoreSymlink "less/lesskey";

        # ripgrep
        ".ripgreprc".source = makeOutOfStoreSymlink "ripgrep/ripgreprc";

        # for any searchers e.g. ripgrep
        ".ignore".source = makeOutOfStoreSymlink "search/ignore";
      };

      xdg.configFile = {
        # lsd
        "lsd".source = makeOutOfStoreSymlink "lsd";

        # pipr
        "pipr/pipr.toml".source = makeOutOfStoreSymlink "pipr/pipr.toml";

        # viddy
        "viddy.toml".source = makeOutOfStoreSymlink "viddy/viddy.toml";

        # watchman
        "watchman/watchman.json".source = makeOutOfStoreSymlink "watchman/watchman.json";
      };
    }
