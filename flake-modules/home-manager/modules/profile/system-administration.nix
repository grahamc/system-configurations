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
        # TODO: One of the check dependencies is a linux-only programs so I'm disabling the check to get this
        # to build on macOS.
        # pull request that introduced it: https://github.com/NixOS/nixpkgs/pull/240911
        (gping.overrideAttrs
          (old: {doCheck = false;})
        )
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
        broot
        yash
      ] ++ optionals isLinux [
        trashy
        pipr
        clear
        catp
        # for pstree
        psmisc
        pbpaste
      ] ++ optionals isDarwin [
        # macOS comes with a very old version of ncurses that doesn't have a terminfo entry for tmux, tmux-256color
        ncurses
        pstree
        trash
      ];

      # Taken from home-manager: https://github.com/nix-community/home-manager/blob/47c2adc6b31e9cff335010f570814e44418e2b3e/modules/programs/broot.nix#L151
      # I'm doing this home-manager was bringing in the broot source code as a dependency.
      #
      # Using mkAfter to make it more likely to appear after other
      # manipulations of the prompt.
      programs.fish.shellInit = lib.mkAfter ''
        source ${
          pkgs.runCommand "br.fish" { nativeBuildInputs = [ pkgs.broot ]; }
          "broot --print-shell-function fish > $out"
        }
      '';
      # Dummy file to prevent broot from trying to reinstall itself
      xdg.configFile."broot" = {
        source = pkgs.writeTextDir "launcher/installed-v1" "";
        recursive = true;
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
