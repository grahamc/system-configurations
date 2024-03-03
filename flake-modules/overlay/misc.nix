{
  inputs,
  self,
  ...
}: {
  flake = let
    overlay = final: prev: let
      ncursesWithWezterm = let
        weztermTerminfo =
          final.runCommand "wezterm-terminfo"
          {nativeBuildInputs = [final.ncurses];}
          ''
            mkdir -p $out/share/terminfo
            tic -x -o $out/share/terminfo ${inputs.wezterm}/termwiz/data/wezterm.terminfo
          '';
      in
        final.symlinkJoin {
          name = "ncursesWithWezterm";
          paths = [
            weztermTerminfo
            final.ncurses
          ];
        };

      latestTmux = prev.tmux.overrideAttrs (old: {
        src = inputs.tmux;
        patches = [];
        configureFlags = old.configureFlags ++ ["--enable-sixel"];
      });

      nightlyNeovimWithDependencies = let
        dependencies = final.symlinkJoin {
          name = "neovim-dependencies";
          postBuild = ''
            ln -s ${inputs.self}/dotfiles/general/executables/conform.bash $out/bin/conform
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
    in {
      tmux = latestTmux;
      # I'm renaming ncurses to avoid rebuilds.
      inherit ncursesWithWezterm;
      neovim = nightlyNeovimWithDependencies;
    };

    metaOverlay = self.lib.overlay.makeMetaOverlay [
      inputs.neovim-nightly-overlay.overlay
      overlay
    ];
  in {overlays.misc = metaOverlay;};
}
