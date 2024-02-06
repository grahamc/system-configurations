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
    in {
      tmux = latestTmux;
      # I'm renaming ncurses to avoid rebuilds.
      inherit ncursesWithWezterm;
      neovim = final.neovim-nightly;
    };

    metaOverlay = self.lib.overlay.makeMetaOverlay [
      overlay
      inputs.neovim-nightly-overlay.overlay
    ];
  in {overlays.misc = metaOverlay;};
}
