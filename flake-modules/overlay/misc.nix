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

      nightlyNeovim = final.symlinkJoin {
        inherit (final.neovim-nightly) name;
        paths = [final.neovim-nightly];
        buildInputs = [final.makeWrapper];
        # Neovim uses unibilium to discover term info entries which is a problem for me because
        # unibilium sets its terminfo search path at build time so I'm setting the search path here.
        postBuild = ''
          wrapProgram $out/bin/nvim --set TERMINFO_DIRS '${ncursesWithWezterm}/share/terminfo'
        '';
      };
    in {
      tmux = latestTmux;
      # I'm renaming ncurses to avoid rebuilds.
      inherit ncursesWithWezterm;
      neovim = nightlyNeovim;
    };

    metaOverlay = self.lib.overlay.makeMetaOverlay [
      overlay
      inputs.neovim-nightly-overlay.overlay
    ];
  in {overlays.misc = metaOverlay;};
}
