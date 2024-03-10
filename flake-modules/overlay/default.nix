{self, ...}: {
  imports = [
    ./plugins
    ./xdg.nix
    ./missing-packages.nix
    ./meta-packages.nix
    ./partial-packages.nix
    ./misc.nix
  ];

  flake = let
    makeMetaOverlay = overlays: final: prev: let
      callOverlay = overlay: overlay final prev;
      overlayResults = builtins.map callOverlay overlays;
      mergedOverlayResults = self.lib.recursiveMerge overlayResults;
    in
      mergedOverlayResults;

    metaOverlay =
      makeMetaOverlay
      [
        self.overlays.plugins
        self.overlays.xdg
        self.overlays.missingPackages
        self.overlays.metaPackages
        self.overlays.partialPackages
        self.overlays.misc
      ];
  in {
    lib.overlay = {inherit makeMetaOverlay;};
    overlays.default = metaOverlay;
  };
}
