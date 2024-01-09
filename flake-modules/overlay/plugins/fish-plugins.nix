{ self, ... }:
  {
    flake = let
      overlay = _final: prev:
        let
          fishPluginRepositoryPrefix = "fish-plugin-";
          fishPluginBuilder = _ignored: repositorySourceCode: _ignored: repositorySourceCode;
          newFishPlugins = self.lib.pluginOverlay.makePluginPackages
            fishPluginRepositoryPrefix
            fishPluginBuilder;
          fishPlugins = prev.fishPlugins // newFishPlugins;
        in
          { inherit fishPlugins; };
    in
      { overlays.fishPlugins = overlay; };
  }

