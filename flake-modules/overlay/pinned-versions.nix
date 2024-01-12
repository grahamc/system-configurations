{inputs, ...}: {
  flake = let
    overlay = final: prev: let
      inherit (prev.stdenv) isDarwin;
      inherit (prev.lib.attrsets) optionalAttrs;
      inherit ((import inputs.nixpkgs-for-wezterm {inherit (final) system;})) wezterm;

      tmux = prev.tmux.overrideAttrs (old: {
        src = prev.fetchFromGitHub {
          owner = "tmux";
          repo = "tmux";
          rev = "f68d35c52962c095e81db0de28219529fd6f355e";
          sha256 = "sha256-xxDPQE7OfsbKkOwZSclxu4qOXK6Ej1ktQ0fyXz65m3k=";
        };
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
