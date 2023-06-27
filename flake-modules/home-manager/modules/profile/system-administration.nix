{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (lib.lists) optionals;
    inherit (pkgs.stdenv) isLinux isDarwin;
    inherit (specialArgs) isGui;
    inherit (lib.attrsets) optionalAttrs;
    fzfWithoutShellConfig = pkgs.buildEnv {
      name = "fzf-bin-only";
      paths = [pkgs.fzf];
      pathsToLink = ["/bin" "/share/man"];
    };
  in
    {
      imports = [
        ../bat.nix
        ../git.nix
      ];

      home.packages = with pkgs; [
        doggo
        duf
        fd
        fzfWithoutShellConfig
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
        # Useful for commands that don't work quite the same way between macOS and Linux
        coreutils-full
        gnugrep
        # Though less is on most machines by default, I added it here because I need a relatively recent version (600)
        # since that's when they added support for XDG Base Directories.
        less
        # These weren't in a docker container
        gnused
      ] ++ optionals isLinux [
        trashy
        pipr
        clear
        catp
        open
        # for pstree
        psmisc
        pbpaste
      ] ++ optionals isDarwin [
        # macOS comes with a very old version of ncurses that doesn't have a terminfo entry for tmux, tmux-256color
        ncurses
        pstree
        trash
      ];

      # I'm enabling this integration so home-manager can handle sourcing broot's shell config file.
      programs.broot = {
        enable = true;
      };

      repository.symlink.home.file = {
        ".ignore".source = "search/ignore";
      };

      repository.symlink.xdg.executable = {
        "fzf-tmux-zoom".source = "fzf/fzf-tmux-zoom";
        "fzf-help-preview".source = "fzf/fzf-help-preview";
        "myssh".source = "ssh/myssh.sh";
      };

      repository.symlink.xdg.configFile = {
        "lsd".source = "lsd";
        "viddy.toml".source = "viddy/viddy.toml";
        "watchman/watchman.json".source = "watchman/watchman.json";
        "lesskey".source = "less/lesskey";
        "fish/conf.d/fzf.fish".source = "fzf/fzf.fish";
        "ripgrep/ripgreprc".source = "ripgrep/ripgreprc";
        "ssh/start-my-shell.sh".source = "ssh/start-my-shell.sh";
        "broot/conf.hjson".source = "broot/conf.hjson";
      } // optionalAttrs isLinux {
        "pipr/pipr.toml".source = "pipr/pipr.toml";
        "fish/conf.d/pipr.fish".source = "pipr/pipr.fish";
      } // optionalAttrs isGui {
        "wezterm/wezterm.lua".source = "wezterm/wezterm.lua";
      };
    }
