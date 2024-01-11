{self, ...}: {
  flake = let
    overlay = _final: prev: let
      rtpFilePathFixes = {
        "tmux-suspend" = "suspend.tmux";
        "better-mouse-mode" = "scroll_copy_mode.tmux";
      };
      applyRtpFilePathFix = tmuxPluginInfo: let
        pluginName = tmuxPluginInfo.pluginName;
        hasFix = builtins.hasAttr pluginName rtpFilePathFixes;
        getFix = pluginName: {rtpFilePath = builtins.getAttr pluginName rtpFilePathFixes;};
      in
        if hasFix
        then tmuxPluginInfo // getFix pluginName
        else tmuxPluginInfo;
      tmuxPluginBuilder = repositoryName: repositorySourceCode: date: let
        pluginInfo = {
          pluginName = repositoryName;
          version = date;
          src = repositorySourceCode;
        };
        pluginInfoWithFix = applyRtpFilePathFix pluginInfo;
      in
        if builtins.hasAttr repositoryName prev.tmuxPlugins
        then
          (builtins.getAttr repositoryName prev.tmuxPlugins).overrideAttrs (_old: {
            version = date;
            src = repositorySourceCode;
          })
        else prev.tmuxPlugins.mkTmuxPlugin pluginInfoWithFix;
      tmuxPluginRepositoryPrefix = "tmux-plugin-";
      newTmuxPlugins =
        self.lib.pluginOverlay.makePluginPackages
        tmuxPluginRepositoryPrefix
        tmuxPluginBuilder;
      tmuxPlugins = prev.tmuxPlugins // newTmuxPlugins;
    in {inherit tmuxPlugins;};
  in {overlays.tmuxPlugins = overlay;};
}
