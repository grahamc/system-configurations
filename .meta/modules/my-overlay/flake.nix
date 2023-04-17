{
  description = "Biggs's overlay";

  inputs = {
    "vim-plugin-vim-CursorLineCurrentWindow" = {url = "github:inkarkat/vim-CursorLineCurrentWindow"; flake = false;};
    "vim-plugin-vCoolor.vim" = {url = "github:KabbAmine/vCoolor.vim"; flake = false;};
    "vim-plugin-virt-column.nvim" = {url = "github:lukas-reineke/virt-column.nvim"; flake = false;};
    "vim-plugin-folding-nvim" = {url = "github:pierreglaser/folding-nvim"; flake = false;};
    "vim-plugin-cmp-env" = {url = "github:bydlw98/cmp-env"; flake = false;};
    "vim-plugin-SchemaStore.nvim" = {url = "github:b0o/SchemaStore.nvim"; flake = false;};
    "vim-plugin-vim" = {url = "github:nordtheme/vim"; flake = false;};
    "vim-plugin-vim-caser" = {url = "github:arthurxavierx/vim-caser"; flake = false;};
  };

  outputs = { ... }@repositories: {
    overlays.default = final: prev:
      let
        filterForVimPlugins = repositories:
          prev.lib.attrsets.filterAttrs
            (repositoryName: repositorySourceCode: (builtins.match "vim-plugin-.*" repositoryName) != null)
            repositories;
        removeVimPluginPrefixFromNames = repositories:
          prev.lib.mapAttrs'
            (repositoryName: repositorySourceCode:
              prev.lib.nameValuePair
                (builtins.elemAt (builtins.match "vim-plugin-(.*)" repositoryName) 0)
                repositorySourceCode
            )
            repositories;
        buildVimPlugins = repositories:
          prev.lib.mapAttrs'
            (repositoryName: repositorySourceCode:
              prev.lib.nameValuePair
                repositoryName
                (prev.vimUtils.buildVimPluginFrom2Nix {
                  pname = repositoryName;
                  # YYYY-MM-DD
                  version = prev.lib.concatStringsSep "-" (builtins.match "(....)(..)(..).*" repositorySourceCode.lastModifiedDate);
                  src = repositorySourceCode;
                })
            )
            repositories;
        newVimPlugins = prev.lib.trivial.pipe
          repositories
          [ filterForVimPlugins removeVimPluginPrefixFromNames buildVimPlugins ];
        allVimPlugins = prev.vimPlugins // newVimPlugins;
      in
        {
          vimPlugins = allVimPlugins;
        };
  };
}
