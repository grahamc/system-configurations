{inputs, ...}: {
  flake = let
    overlay = final: prev: let
      inherit (prev.stdenv) isDarwin;
      inherit (prev.lib.attrsets) optionalAttrs;
      inherit ((import inputs.nixpkgs-for-wezterm {inherit (final) system;})) wezterm;

      tmux = prev.tmux.overrideAttrs (old: {
        src = inputs.tmux;
        patches = [];
        configureFlags = old.configureFlags ++ ["--enable-sixel"];
      });
    in
      {
        inherit tmux;
      }
      // optionalAttrs isDarwin {
        inherit wezterm;
      };
  in {overlays.pinnedVersions = overlay;};
}
