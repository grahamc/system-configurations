{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (lib.lists) optionals;
    inherit (pkgs.stdenv) isLinux isDarwin;
    inherit (lib.attrsets) optionalAttrs;
    inherit (specialArgs) xdgPkgs;
  in
    {
      imports = [
        ../bat.nix
        ../git.nix
        ../tmux.nix
        ../wezterm.nix
        ../fbterm.nix
        ../keyboard-shortcuts.nix
        ../fonts.nix
      ];

      home.packages = with pkgs; [
        doggo
        duf
        fd
        fzf
        gping
        jq
        lsd
        moreutils
        ncdu
        xdgPkgs.ripgrep
        tealdeer
        tree
        viddy
        zoxide
        file
        # Useful for commands that don't work quite the same way between macOS and Linux
        coreutils-full
        # Though less is on most machines by default, I added it here because I need a relatively recent version (600)
        # since that's when they added support for XDG Base Directories.
        less
        # These weren't in a docker container
        gnused
      ] ++ optionals isLinux [
        trash-cli
        pipr
        clear
        catp
      ] ++ optionals isDarwin [
        # macOS comes with a very old version of ncurses that doesn't have a terminfo entry for tmux, tmux-256color
        ncurses
      ];

      repository.symlink.home.file = {
        ".ignore".source = "search/ignore";
        ".local/bin/fzf-tmux-zoom".source = "fzf/fzf-tmux-zoom";
        ".local/bin/fzf-help-preview".source = "fzf/fzf-help-preview";
        ".local/bin/myssh".source = "ssh/myssh.sh";
      } // optionalAttrs isLinux {
        ".local/bin/pbcopy".source = "general/executables/osc-copy";
      };

      home.file = optionalAttrs isLinux {
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

      repository.symlink.xdg.configFile = {
        "lsd".source = "lsd";
        "viddy.toml".source = "viddy/viddy.toml";
        "watchman/watchman.json".source = "watchman/watchman.json";
        "lesskey".source = "less/lesskey";
        "fish/conf.d/fzf.fish".source = "fzf/fzf.fish";
        "ripgrep/ripgreprc".source = "ripgrep/ripgreprc";
        "ssh/start-my-shell.sh".source = "ssh/start-my-shell.sh";
      } // optionalAttrs isLinux {
        "pipr/pipr.toml".source = "pipr/pipr.toml";
        "fish/conf.d/pipr.fish".source = "pipr/pipr.fish";
      };
    }
