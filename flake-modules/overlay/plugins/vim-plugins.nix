{self, ...}: {
  flake = let
    overlay = final: prev: let
      vimPluginRepositoryPrefix = "vim-plugin-";

      vimPluginBuilder = repositoryName: repositorySourceCode: date:
        if builtins.hasAttr repositoryName prev.vimPlugins
        then
          (builtins.getAttr repositoryName prev.vimPlugins).overrideAttrs (_old: {
            name = "${repositoryName}-${date}";
            version = date;
            src = repositorySourceCode;
          })
        else
          prev.vimUtils.buildVimPlugin {
            pname = repositoryName;
            version = date;
            src = repositorySourceCode;
          };

      newVimPlugins =
        self.lib.pluginOverlay.makePluginPackages
        vimPluginRepositoryPrefix
        vimPluginBuilder;

      treesitter-parsers = final.symlinkJoin {
        name = "treesitter-parsers";
        paths = newVimPlugins.nvim-treesitter.withAllGrammars.dependencies;
      };

      vimPlugins =
        prev.vimPlugins
        // newVimPlugins
        // {
          inherit treesitter-parsers;
          # remove treesitter parser plugins because they were ending up in my
          # 'plugged' directory
          nvim-treesitter = newVimPlugins.nvim-treesitter.withPlugins (_: []);
        };
    in {inherit vimPlugins;};
  in {overlays.vimPlugins = overlay;};
}
