{inputs, ...}: {
  flake = let
    overlay = final: prev: let
      tmux = let
        wrapped =
          final.writeShellScriptBin
          "tmux"
          # I want the $SHLVL to start from one for any shells launched in TMUX since they technically aren't
          # children of the shell that I launched TMUX with. I would do this with TMUX's `default-command`, but
          # that may break tmux-resurrect, as explained in my tmux.conf.
          ''
            exec env -u SHLVL ${prev.tmux}/bin/tmux "$@"
          '';
      in
        final.symlinkJoin {
          name = "tmux";
          paths = [
            wrapped
            prev.tmux
          ];
        };

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
    in {
      # I'm renaming ncurses to avoid rebuilds.
      inherit tmux ncursesWithWezterm;
    };
  in {overlays.misc = overlay;};
}
