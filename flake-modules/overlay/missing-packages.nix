{inputs, ...}: {
  flake = let
    overlay = final: prev: let
      inherit (prev.stdenv) isLinux;
      inherit (prev.lib.attrsets) optionalAttrs;

      catp = final.stdenv.mkDerivation {
        pname = "catp";
        version = "0.2.0";
        src = prev.fetchzip {
          url = "https://github.com/rapiz1/catp/releases/download/v0.2.0/catp-x86_64-unknown-linux-gnu.zip";
          sha256 = "sha256-U7h/Ecm+8oXy8Zr+Rq25eSiZw/2/GuUCFvnCtuc7pT8=";
        };
        installPhase = ''
          mkdir -p $out/bin
          cp $src/catp $out/bin/
        '';
      };

      nonicons =
        final.runCommand "nonicons"
        {}
        ''
          mkdir -p $out/share/fonts/truetype
          ln --symbolic ${inputs.self}/dotfiles/nonicons/dist/nonicons.ttf $out/share/fonts/truetype/nonicons.ttf
        '';
    in
      {
        inherit nonicons;
      }
      // optionalAttrs isLinux {
        inherit catp;
      };
  in {overlays.missingPackages = overlay;};
}
