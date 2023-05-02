{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      makeSymlinkToRepo
      ;
    inherit (lib.lists) optionals;
    inherit (pkgs.stdenv) isLinux isDarwin;
    inherit (lib.attrsets) optionalAttrs;
    inherit (specialArgs) xdgPkgs;
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
      ] ++ optionals isDarwin [
        # macOS comes with a very old version of ncurses that doesn't have a terminfo entry for tmux, tmux-256color
        ncurses
      ];

      home.file = {
        ".ignore".source = makeSymlinkToRepo "search/ignore";
        ".local/bin/fzf-tmux-zoom".source = makeSymlinkToRepo "fzf/fzf-tmux-zoom";
        ".local/bin/fzf-help-preview".source = makeSymlinkToRepo "fzf/fzf-help-preview";
        ".local/bin/myssh" = {
          source = makeSymlinkToRepo "ssh/myssh.sh";
        };
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
        "lsd".source = makeSymlinkToRepo "lsd";
        "viddy.toml".source = makeSymlinkToRepo "viddy/viddy.toml";
        "watchman/watchman.json".source = makeSymlinkToRepo "watchman/watchman.json";
        "lesskey".source = makeSymlinkToRepo "less/lesskey";
        "fish/conf.d/fzf.fish".source = makeSymlinkToRepo "fzf/fzf.fish";
        "ripgrep/ripgreprc".source = makeSymlinkToRepo "ripgrep/ripgreprc";
        "ssh/start-my-shell.sh".source = makeSymlinkToRepo "ssh/start-my-shell.sh";
      } // optionalAttrs isLinux {
        "pipr/pipr.toml".source = makeSymlinkToRepo "pipr/pipr.toml";
        "fish/conf.d/pipr.fish".source = makeSymlinkToRepo "pipr/pipr.fish";
      };
    }
