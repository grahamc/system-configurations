{
  self,
  inputs,
  ...
}: {
  flake = let
    overlay = final: prev: let
      rtpFilePathFixes = {
        "tmux-suspend" = "suspend.tmux";
        "better-mouse-mode" = "scroll_copy_mode.tmux";
      };
      applyRtpFilePathFix = tmuxPluginInfo: let
        inherit (tmuxPluginInfo) pluginName;
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
      tmuxPlugins =
        prev.tmuxPlugins
        // newTmuxPlugins
        // {
          sidebar = prev.tmuxPlugins.mkTmuxPlugin {
            version = "next";
            pluginName = "tmux-sidebar";
            rtpFilePath = "sidebar.tmux";
            src =
              final.runCommand
              "sidebar"
              {}
              ''
                cp -R --dereference ${inputs.tmux-plugin-sidebar} $out
                # so we can write
                chmod +w -R $out

                # The original script tried comparing the name of a command with a number so I'm replacing
                # the command with its output.
                target='tmux_version_int'
                # First grep so the build will error out if the string isn't present
                grep -q "$target" "$out/scripts/toggle.sh"
                sed -e "s@$target@34@" <"${inputs.tmux-plugin-sidebar}/scripts/toggle.sh" >"$out/scripts/toggle.sh"

                # The `\t` in the grep pattern wasn't matching so I'm replacing it with `$'\t'`
                target='\\t"'
                # First grep so the build will error out if the string isn't present
                grep -q "$target" "$out/scripts/helpers.sh"
                sed -e "s@$target@"'"'"\$'\\t'@g" <"${inputs.tmux-plugin-sidebar}/scripts/helpers.sh" >"$out/scripts/helpers.sh"
              '';
          };
        };
    in {inherit tmuxPlugins;};
  in {overlays.tmuxPlugins = overlay;};
}
