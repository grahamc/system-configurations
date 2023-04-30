{
  description = "Biggs's overlay";

  inputs = {
    "vim-plugin-vim-CursorLineCurrentWindow" = {url = "github:inkarkat/vim-CursorLineCurrentWindow"; flake = false;};
    "vim-plugin-virt-column.nvim" = {url = "github:lukas-reineke/virt-column.nvim"; flake = false;};
    "vim-plugin-folding-nvim" = {url = "github:pierreglaser/folding-nvim"; flake = false;};
    "vim-plugin-cmp-env" = {url = "github:bydlw98/cmp-env"; flake = false;};
    "vim-plugin-SchemaStore.nvim" = {url = "github:b0o/SchemaStore.nvim"; flake = false;};
    "vim-plugin-vim" = {url = "github:nordtheme/vim"; flake = false;};
    "vim-plugin-vim-caser" = {url = "github:arthurxavierx/vim-caser"; flake = false;};

    "tmux-plugin-resurrect" = {url = "github:tmux-plugins/tmux-resurrect"; flake = false;};
    "tmux-plugin-tmux-suspend" = {url = "github:MunifTanjim/tmux-suspend"; flake = false;};

    "fish-plugin-fish-abbreviation-tips" = {url = "github:gazorby/fish-abbreviation-tips"; flake = false;};
    "fish-plugin-autopair-fish" = {url = "github:jorgebucaran/autopair.fish"; flake = false;};
    "fish-plugin-async-prompt" = {url = "github:acomagu/fish-async-prompt"; flake = false;};
  };

  outputs = { ... }@repositories: {
    overlays.default = currentNixpkgs: previousNixpkgs:
      let
        inherit (previousNixpkgs.stdenv) isLinux;
        inherit (previousNixpkgs.lib.attrsets) optionalAttrs;

        # YYYYMMDDHHMMSS -> YYYY-MM-DD
        formatDate = date:
          let
            yearMonthDayStrings = builtins.match "(....)(..)(..).*" date;
          in
            previousNixpkgs.lib.concatStringsSep
              "-"
              yearMonthDayStrings;

        # repositoryPrefix:
        # builder: (repositoryName: repositorySourceCode: date: derivation)
        #
        # returns: A set with the form {<repo name with `repositoryPrefix` removed> = derivation}
        makePackages = repositoryPrefix: builder:
          let
            hasPrefix = string: (builtins.match "${repositoryPrefix}.*" string) != null;
            filterRepositoriesForPrefix = repositories:
              previousNixpkgs.lib.attrsets.filterAttrs
                (repositoryName: _ignored: hasPrefix repositoryName)
                repositories;
            
            removePrefix = string:
              let
                matches = builtins.match "${repositoryPrefix}(.*)" string;
                stringWithoutPrefix = builtins.elemAt matches 0;
              in
                stringWithoutPrefix;
            removePrefixFromRepositories = repositories:
              previousNixpkgs.lib.mapAttrs'
                (repositoryName: repositorySourceCode:
                  let
                    repositoryNameWithoutPrefix = removePrefix repositoryName;
                  in
                    previousNixpkgs.lib.nameValuePair
                      repositoryNameWithoutPrefix
                      repositorySourceCode
                )
                repositories;

            buildPackage = repositoryName: repositorySourceCode:
              let
                date = formatDate repositorySourceCode.lastModifiedDate;
              in
                builder repositoryName repositorySourceCode date;
            buildPackagesFromRepositories = repositories: previousNixpkgs.lib.mapAttrs buildPackage repositories;
          in
            previousNixpkgs.lib.trivial.pipe
              repositories
              [ filterRepositoriesForPrefix removePrefixFromRepositories buildPackagesFromRepositories ];
        
        vimPluginRepositoryPrefix = "vim-plugin-";
        vimPluginBuilder = repositoryName: repositorySourceCode: date:
          previousNixpkgs.vimUtils.buildVimPluginFrom2Nix {
            pname = repositoryName;
            version = date;
            src = repositorySourceCode;
          };
        newVimPlugins = makePackages
          vimPluginRepositoryPrefix
          vimPluginBuilder;
        allVimPlugins = previousNixpkgs.vimPlugins // newVimPlugins;

        rtpFilePathFixes = {
          "tmux-suspend" = "suspend.tmux";
        };
        applyRtpFilePathFix = tmuxPluginInfo:
          let
            pluginName = tmuxPluginInfo.pluginName;
            hasFix = builtins.hasAttr pluginName rtpFilePathFixes;
            getFix = pluginName: {rtpFilePath = builtins.getAttr pluginName rtpFilePathFixes;};
          in
            if hasFix
              then tmuxPluginInfo // getFix pluginName
              else tmuxPluginInfo;
        tmuxPluginBuilder = repositoryName: repositorySourceCode: date:
          let
            pluginInfo = {
              pluginName = repositoryName;
              version = date;
              src = repositorySourceCode;
            };
            pluginInfoWithFix = applyRtpFilePathFix pluginInfo;
          in
            previousNixpkgs.tmuxPlugins.mkTmuxPlugin pluginInfoWithFix;
        tmuxPluginRepositoryPrefix = "tmux-plugin-";
        newTmuxPlugins = makePackages
          tmuxPluginRepositoryPrefix
          tmuxPluginBuilder;
        allTmuxPlugins = previousNixpkgs.tmuxPlugins // newTmuxPlugins;

        fishPluginRepositoryPrefix = "fish-plugin-";
        fishPluginBuilder = _ignored: repositorySourceCode: _ignored: repositorySourceCode;
        newFishPlugins = makePackages
          fishPluginRepositoryPrefix
          fishPluginBuilder;
        allFishPlugins = previousNixpkgs.fishPlugins // newFishPlugins;

        crossPlatformPackages = {
          vimPlugins = allVimPlugins;
          tmuxPlugins = allTmuxPlugins;
          fishPlugins = allFishPlugins;
        };
        linuxOnlyPackages = optionalAttrs isLinux {
          clear = previousNixpkgs.symlinkJoin {
            name = "clear";
            paths = [previousNixpkgs.busybox];
            buildInputs = [previousNixpkgs.makeWrapper];
            # clear is a symlink to busybox so remove everything except those two.
            postBuild = ''
              cd $out
              find . ! -name 'clear' ! -name 'busybox' -type f,l -exec rm -f {} +
            '';
          };
        };
        allPackages = crossPlatformPackages // linuxOnlyPackages;
      in
        allPackages;
  };
}
