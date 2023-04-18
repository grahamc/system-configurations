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

    "tmux-plugin-resurrect" = {url = "github:tmux-plugins/tmux-resurrect"; flake = false;};
    "tmux-plugin-tmux-volume" = {url = "github:levex/tmux-plugin-volume"; flake = false;};
    "tmux-plugin-tmux-suspend" = {url = "github:MunifTanjim/tmux-suspend"; flake = false;};

    "fish-plugin-fish-abbreviation-tips" = {url = "github:gazorby/fish-abbreviation-tips"; flake = false;};
    "fish-plugin-autopair-fish" = {url = "github:jorgebucaran/autopair.fish"; flake = false;};
    "fish-plugin-async-prompt" = {url = "github:acomagu/fish-async-prompt"; flake = false;};
  };

  outputs = { ... }@repositories: {
    overlays.default = final: prev:
      let
        makePrefixRemover = prefix:
          repositories:
            prev.lib.mapAttrs'
              (repositoryName: repositorySourceCode:
                prev.lib.nameValuePair
                  (builtins.elemAt (builtins.match "${prefix}(.*)" repositoryName) 0)
                  repositorySourceCode
              )
              repositories;

        makePrefixFilter = prefix:
          repositories:
            prev.lib.attrsets.filterAttrs
              (repositoryName: _ignored: (builtins.match "${prefix}.*" repositoryName) != null)
              repositories;

        formatDate = date:
          prev.lib.concatStringsSep
            "-"
            (builtins.match "(....)(..)(..).*" date);

        makePackages = prefix: builder:
          let
            filterForPrefix = makePrefixFilter prefix;
            removePrefix = makePrefixRemover prefix;
            callBuilderWithDate = repositories:
              prev.lib.mapAttrs
                (repositoryName: repositorySourceCode:
                  let
                    date = formatDate repositorySourceCode.lastModifiedDate;
                  in
                    (builder repositoryName repositorySourceCode date)
                )
                repositories;
          in
            prev.lib.trivial.pipe
              repositories
              [ filterForPrefix removePrefix callBuilderWithDate ];

        newVimPlugins = makePackages
          "vim-plugin-"
          (repositoryName: repositorySourceCode: date:
            (prev.vimUtils.buildVimPluginFrom2Nix {
              pname = repositoryName;
              version = date;
              src = repositorySourceCode;
            })
          );
        allVimPlugins = prev.vimPlugins // newVimPlugins;

        newTmuxPlugins = makePackages
          "tmux-plugin-"
          (repositoryName: repositorySourceCode: date:
            (prev.tmuxPlugins.mkTmuxPlugin {
              pluginName = repositoryName;
              version = date;
              src = repositorySourceCode;
            })
          );
        allTmuxPlugins = prev.tmuxPlugins // newTmuxPlugins;

        newFishPlugins = makePackages
          "fish-plugin-"
          (_ignored: repositorySourceCode: _ignored: repositorySourceCode);
        allFishPlugins = prev.fishPlugins // newFishPlugins;
      in
        {
          vimPlugins = allVimPlugins;
          tmuxPlugins = allTmuxPlugins;
          fishPlugins = allFishPlugins;
        };
  };
}
