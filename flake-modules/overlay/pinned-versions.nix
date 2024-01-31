{inputs, ...}: {
  flake = let
    overlay = final: prev: let
      inherit (prev.stdenv) isDarwin;
      inherit (prev.lib.attrsets) optionalAttrs;
      inherit ((import inputs.nixpkgs-for-wezterm {inherit (final) system;})) wezterm;
    in
      optionalAttrs isDarwin {
        inherit wezterm;
      };
  in {overlays.pinnedVersions = overlay;};
}
