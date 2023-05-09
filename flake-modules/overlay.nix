{ inputs, ... }:
  {
    flake =
      let
        overlay = final: prev:
          let
            inherit (prev.stdenv) isLinux;
            inherit (prev.lib.attrsets) optionalAttrs;

            # YYYYMMDDHHMMSS -> YYYY-MM-DD
            formatDate = date:
              let
                yearMonthDayStrings = builtins.match "(....)(..)(..).*" date;
              in
                prev.lib.concatStringsSep
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
                  prev.lib.attrsets.filterAttrs
                    (repositoryName: _ignored: hasPrefix repositoryName)
                    repositories;
                
                removePrefix = string:
                  let
                    matches = builtins.match "${repositoryPrefix}(.*)" string;
                    stringWithoutPrefix = builtins.elemAt matches 0;
                  in
                    stringWithoutPrefix;
                removePrefixFromRepositories = repositories:
                  prev.lib.mapAttrs'
                    (repositoryName: repositorySourceCode:
                      let
                        repositoryNameWithoutPrefix = removePrefix repositoryName;
                      in
                        prev.lib.nameValuePair
                          repositoryNameWithoutPrefix
                          repositorySourceCode
                    )
                    repositories;

                buildPackage = repositoryName: repositorySourceCode:
                  let
                    date = formatDate repositorySourceCode.lastModifiedDate;
                  in
                    builder repositoryName repositorySourceCode date;
                buildPackagesFromRepositories = repositories: prev.lib.mapAttrs buildPackage repositories;
              in
                prev.lib.trivial.pipe
                  inputs
                  [ filterRepositoriesForPrefix removePrefixFromRepositories buildPackagesFromRepositories ];
            
            vimPluginRepositoryPrefix = "vim-plugin-";
            vimPluginBuilder = repositoryName: repositorySourceCode: date:
              prev.vimUtils.buildVimPluginFrom2Nix {
                pname = repositoryName;
                version = date;
                src = repositorySourceCode;
              };
            newVimPlugins = makePackages
              vimPluginRepositoryPrefix
              vimPluginBuilder;
            allVimPlugins = prev.vimPlugins // newVimPlugins;

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
                prev.tmuxPlugins.mkTmuxPlugin pluginInfoWithFix;
            tmuxPluginRepositoryPrefix = "tmux-plugin-";
            newTmuxPlugins = makePackages
              tmuxPluginRepositoryPrefix
              tmuxPluginBuilder;
            allTmuxPlugins = prev.tmuxPlugins // newTmuxPlugins;

            fishPluginRepositoryPrefix = "fish-plugin-";
            fishPluginBuilder = _ignored: repositorySourceCode: _ignored: repositorySourceCode;
            newFishPlugins = makePackages
              fishPluginRepositoryPrefix
              fishPluginBuilder;
            allFishPlugins = prev.fishPlugins // newFishPlugins;

            crossPlatformPackages = {
              vimPlugins = allVimPlugins;
              tmuxPlugins = allTmuxPlugins;
              fishPlugins = allFishPlugins;
            };
            linuxOnlyPackages = optionalAttrs isLinux {
              clear = prev.symlinkJoin {
                name = "clear";
                paths = [prev.busybox];
                buildInputs = [prev.makeWrapper];
                # clear is a symlink to busybox so remove everything except those two.
                postBuild = ''
                  cd $out
                  find . ! -name 'clear' ! -name 'busybox' -type f,l -exec rm -f {} +
                '';
              };
              catp = prev.stdenv.mkDerivation {
                pname = "catp";
                version = "0.2.0";
                src = prev.fetchzip {
                  url = "https://github.com/rapiz1/catp/releases/download/v0.2.0/catp-x86_64-unknown-linux-gnu.zip";
                  sha256 = "sha256-U7h/Ecm+8oXy8Zr+Rq25eSiZw/2/GuUCFvnCtuc7pT8=";
                };
                installPhase = ''
                  mkdir -p $out/bin
                  cp $src/catp $out/bin/
                '';
              };
            };

            xdgModule = import "${inputs.nix-xdg}/module.nix";
            xdgModuleContents = xdgModule {pkgs = prev; inherit (prev) lib; config = {};};
            xdgOverlay = xdgModuleContents.config.lib.xdg.xdgOverlay
              {
                specs = {
                  ripgrep.env.RIPGREP_CONFIG_PATH = {config}: "${config}/ripgreprc";
                  watchman.env.WATCHMAN_CONFIG_FILE = {config}: "${config}/watchman.json";
                  figlet.env.FIGLET_FONTDIR = {data}: data;
                };
              };
            # TODO: It's a bit awkward that I'm creating a new nixpkgs instance only to extract the few packages that I
            # wrapped.
            xdgPkgs = import inputs.nixpkgs {
              inherit (prev.stdenv) system;
              overlays = [ xdgOverlay ];
            };
            # I put these packages under 'xdgWrappers' so they don't overwrite the originals. This is to avoid rebuilds
            # of tools that depend on anything wrapped in this overlay. This is fine since I only need XDG Base Directory
            # compliance when I'm using a program directly.
            xdgWrappers = {
              xdgWrappers = {
                inherit (xdgPkgs) ripgrep watchman figlet;
              };
            };

            allPackages = crossPlatformPackages // linuxOnlyPackages // xdgWrappers;
          in
            allPackages;

        overlayOutput = {
          overlays.default = overlay;
        };
      in
        overlayOutput;
  }
