{
  inputs,
  self,
  ...
}: {
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

      treesitter-parsers = let
        just-grammar = final.tree-sitter.buildGrammar {
          language = "just";
          version = inputs.vim-plugin-tree-sitter-just.rev;
          src = inputs.vim-plugin-tree-sitter-just;
        };
        updatedGrammars = newVimPlugins.nvim-treesitter.allGrammars ++ [just-grammar];
        package = newVimPlugins.nvim-treesitter.withPlugins (_: updatedGrammars);
      in
        final.symlinkJoin {
          name = "treesitter-parsers";
          paths = package.dependencies;
        };

      nvim-nonicons =
        vimPluginBuilder
        "nvim-nonicons"
        (final.runCommand "nvim-nonicons" {} ''cp -R --dereference ${inputs.self}/dotfiles/nonicons/nvim $out'')
        "next";

      vimPlugins =
        prev.vimPlugins
        // newVimPlugins
        // {
          inherit treesitter-parsers nvim-nonicons;
          # remove treesitter parser plugins because they were ending up in my 'plugged' directory
          nvim-treesitter = newVimPlugins.nvim-treesitter.withPlugins (_: []);
        };
    in {inherit vimPlugins;};
  in {overlays.vimPlugins = overlay;};
}
