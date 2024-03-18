{
  inputs,
  lib,
  ...
}: {
  flake = let
    overlay = final: prev: let
      inherit (final.stdenv) isLinux;

      ncursesWithWezterm = final.symlinkJoin {
        name = "ncursesWithWezterm";
        paths = [
          final.wezterm.terminfo
          final.ncurses
        ];
      };

      latestTmux = prev.tmux.overrideAttrs (_old: {
        src = inputs.tmux;
        patches = [];
      });

      nightlyNeovimWithDependencies = let
        dependencies = final.symlinkJoin {
          name = "neovim-dependencies";
          postBuild = ''
            ln -s ${inputs.self}/dotfiles/general/executables/conform.bash $out/bin/conform
            ln -s ${inputs.self}/dotfiles/general/executables/pbcopy $out/bin/pbcopy
            ln -s ${inputs.self}/dotfiles/general/executables/trash-macos $out/bin/trash
          '';
          paths = with final; [
            # to format comments
            par

            # for cmp-dictionary
            partialPackages.look
            wordnet

            # For the conform.nvim formatters 'trim_whitespace' and 'squeeze_blanks' which require awk and
            # cat respectively
            gawk
            coreutils-full

            # for mason.nvim. need to specify `final` here because otherwise it will resolve to the
            # attribute inside `let` and overlays won't be able to override it
            final.myPython

            # for telescope-sg
            ast-grep

            # for telescope
            fd
            xdgWrappers.ripgrep
          ];
        };
      in
        final.symlinkJoin {
          inherit (final.neovim-nightly) name;
          paths = [final.neovim-nightly];
          buildInputs = [final.makeWrapper];
          postBuild = ''
            # TERMINFO: Neovim uses unibilium to discover term info entries which is a problem for
            # me because unibilium sets its terminfo search path at build time so I'm setting the
            # search path here.
            #
            # PARINIT: Not sure what it means, but the par man page said to use it and it seems to
            # work
            wrapProgram $out/bin/nvim \
              --prefix PATH : '${dependencies}/bin' \
              --set TERMINFO_DIRS '${ncursesWithWezterm}/share/terminfo' \
              --set PARINIT 'rTbgqR B=.\,?'"'"'_A_a_@ Q=_s>|'
          '';
        };

      ripgrepAllWithDependencies = let
        dependencies = final.symlinkJoin {
          name = "ripgrep-all-dependencies";
          paths = with final; [
            xlsx2csv
            fastgron
            tesseract
            djvulibre
          ];
        };
      in
        final.symlinkJoin {
          inherit (prev.ripgrep-all) name;
          paths = [prev.ripgrep-all];
          buildInputs = [final.makeWrapper];
          postBuild = ''
            wrapProgram $out/bin/rga --prefix PATH : '${dependencies}/bin'
          '';
        };

      # TODO: Python virtualenvs use the canonical path of the base python. This is an issue for Nix
      # because when I update my system and the old python gets garbage collected, it breaks any
      # virtualenvs made against it. So I made a wrapper that injects the --copies flag whenever a
      # virtualenv is being made.
      myPython = let
        pythonWithPackages = final.python3.withPackages (ps: with ps; [pip mypy ipython]);
        python3CopyVenvsByDefault =
          final.writeShellApplication
          {
            name = "python";
            text = ''
              new_args=()
              seen_m=""
              seen_venv=""
              for arg in "$@"; do
                new_args=("''${new_args[@]}" "$arg")
                  if [ "$arg" = '-m' ]; then
                    seen_m=1
                      elif [ -n "$seen_m" ] && [ -z "$seen_venv" ] && [ "$arg" = 'venv' ] && [ -z "''${BIGOLU_NO_COPY:-}" ]; then
                      new_args=("''${new_args[@]}" "--copies")
                      seen_venv=1
                      printf '\nInjecting the "--copies" flag into the venv command. This is to avoid breaking virtual environments when Nix does garbage collection. You can disable this injection by setting the environment variable "BIGOLU_NO_COPY=1"\n\n'
                      fi
                      done

                      exec ${pythonWithPackages}/bin/python "''${new_args[@]}"
            '';
          };

        python3CopyVenvsByDefaultPackage =
          final.runCommand
          "python-copy-venvs"
          {}
          ''
            mkdir -p $out/bin
            name="$(find ${pythonWithPackages}/bin -printf '%f\n' | grep -E '^python3\.[0-9]+(\.[0-9]+)?$')"
            cp ${python3CopyVenvsByDefault}/bin/python "$out/bin/$name"
            cp ${python3CopyVenvsByDefault}/bin/python "$out/bin/python"
            cp ${python3CopyVenvsByDefault}/bin/python "$out/bin/python3"
          '';
      in
        final.symlinkJoin {
          name = "myPython";
          paths = [
            python3CopyVenvsByDefaultPackage
            pythonWithPackages
          ];
        };
    in {
      tmux = latestTmux;
      # I'm renaming ncurses and python to avoid rebuilds.
      inherit ncursesWithWezterm myPython;
      neovim = nightlyNeovimWithDependencies;
      ripgrep-all = ripgrepAllWithDependencies;
      # TODO: The wezterm flake doesn't work for macOS. When I try to build it I get an error
      # because the attribute 'UserNotifications' does not exist. The only mention of a similar
      # issue is here:
      # https://github.com/wez/wezterm/issues/2021
      # Based on the above issue, it seems like the problem is due to Nix's outdated Apple SDK. The
      # The following issues/discussions track the status of Apple SDKs in Nix:
      # https://github.com/NixOS/nixpkgs/issues/116341
      # https://discourse.nixos.org/t/nix-macos-monthly/12330
      wezterm =
        if isLinux
        # TODO: get upstream to set meta.mainProgram
        then inputs.wezterm.packages.${final.system}.default // {meta.mainProgram = "wezterm";}
        else (import inputs.nixpkgs-for-wezterm-darwin {inherit (final) system;}).wezterm;
    };
  in {
    overlays.misc = lib.composeManyExtensions [
      inputs.neovim-nightly-overlay.overlay
      overlay
    ];
  };
}
