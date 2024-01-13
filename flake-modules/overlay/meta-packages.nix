_: {
  flake = let
    overlay = final: _prev: let
      myFonts = final.symlinkJoin {
        name = "my-fonts";
        paths = with final; [
          (nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
          iosevka-comfy.comfy-fixed
          iosevka-comfy.comfy-wide-duo
        ];
      };
    in {inherit myFonts;};
  in {overlays.metaPackages = overlay;};
}
