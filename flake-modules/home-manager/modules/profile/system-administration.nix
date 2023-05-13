{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (lib.lists) optionals;
    inherit (pkgs.stdenv) isLinux isDarwin;
    inherit (lib.attrsets) optionalAttrs;
    open = pkgs.writeShellApplication
      {
        name = "open";
        runtimeInputs = [pkgs.xdg-utils];
        text = ''
          xdg-open "''$@"
        '';
      };
  in
    {
      imports = [
        ../bat.nix
        ../git.nix
        ../fbterm.nix
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
        xdgWrappers.ripgrep
        tealdeer
        tree
        viddy
        zoxide
        file
        pstree
        # Useful for commands that don't work quite the same way between macOS and Linux
        coreutils-full
        gnugrep
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
        open
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
      } // optionalAttrs isDarwin {
        ".local/bin/trash" = {
          text = ''
            #!${pkgs.python3}/bin/python3
            import os
            import sys
            import subprocess

            if len(sys.argv) > 1:
                files = []
                for arg in sys.argv[1:]:
                    if os.path.exists(arg):
                        p = os.path.abspath(arg).replace('\\', '\\\\').replace('"', '\\"')
                        files.append('the POSIX file "' + p + '"')
                    else:
                        sys.stderr.write(
                            "%s: %s: No such file or directory\n" % (sys.argv[0], arg))
                if len(files) > 0:
                    cmd = ['osascript', '-e',
                          'tell app "Finder" to move {' + ', '.join(files) + '} to trash']
                    r = subprocess.call(cmd, stdout=open(os.devnull, 'w'))
                    sys.exit(r if len(files) == len(sys.argv[1:]) else 1)
            else:
                sys.stderr.write(
                    'usage: %s file(s)\n'
                    '       move file(s) to Trash\n' % os.path.basename(sys.argv[0]))
                sys.exit(64) # matches what rm does on my system
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
