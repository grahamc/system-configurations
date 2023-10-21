{ inputs, ... }:
  {
    flake =
      let
        overlay = final: prev:
          let
            inherit (prev.stdenv) isLinux isDarwin;
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
                
                removePrefixFromRepositories = repositories:
                  prev.lib.mapAttrs'
                    (repositoryName: repositorySourceCode:
                      let
                        repositoryNameWithoutPrefix = prev.lib.strings.removePrefix repositoryPrefix repositoryName;
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
              prev.vimUtils.buildVimPlugin {
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

            # Lets me starts a nix shell with python and the specified python packages.
            # Example: `pynix requests marshmallow`
            pynix = prev.writeShellApplication
              {
                name = "pynix";
                runtimeInputs = with final; [any-nix-shell];
                text = ''
                  packages="''$(printf "%s\n" "$@" | xargs -I PACKAGE printf "python3Packages.PACKAGE ")"
                  eval ".any-nix-shell-wrapper fish -p ''$packages"
                '';
              };

            xdgModule = import "${inputs.nix-xdg}/module.nix";
            # The intended way to use the nix-xdg is through a module, but I only want to use the overlay so
            # instead I call the module function here just to get the overlay out.
            xdgModuleContents = xdgModule {pkgs = prev; inherit (prev) lib; config = {};};
            xdgOverlay = xdgModuleContents.config.lib.xdg.xdgOverlay
              {
                specs = {
                  ripgrep.env.RIPGREP_CONFIG_PATH = {config}: "${config}/ripgreprc";
                  watchman.env.WATCHMAN_CONFIG_FILE = {config}: "${config}/watchman.json";
                  figlet.env.FIGLET_FONTDIR = {data}: data;
                };
              };

            tmux = prev.tmux.overrideAttrs (old: {
              src = prev.fetchFromGitHub {
                owner = "tmux";
                repo = "tmux";
                rev = "f68d35c52962c095e81db0de28219529fd6f355e";
                sha256 = "sha256-xxDPQE7OfsbKkOwZSclxu4qOXK6Ej1ktQ0fyXz65m3k=";
              };
              patches = [];
              configureFlags = old.configureFlags ++ ["--enable-sixel"];
            });

            crossPlatformPackages = {
              vimPlugins = allVimPlugins;
              tmuxPlugins = allTmuxPlugins;
              fishPlugins = allFishPlugins;
              inherit pynix;
              inherit tmux;
              # I put these packages under 'xdgWrappers' so they don't overwrite the originals. This is to avoid
              # rebuilds of tools that depend on anything wrapped in this overlay. This is fine since I only need
              # XDG Base Directory compliance when I'm using a program directly.
              xdgWrappers = xdgOverlay final prev;
              iosevka = prev.iosevka.override rec {
                privateBuildPlan = ''
                  [buildPlans.iosevka-${set}]
                  family = "Iosevka Biggs"
                  spacing = "term"
                  serifs = "sans"
                  no-cv-ss = false
                  export-glyph-names = false
                  no-ligation = true
                '';
                set = "biggs";
              };
            };

            linuxOnlyPackages = optionalAttrs isLinux {
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

            darwinOnlyPackages = optionalAttrs isDarwin {
              # I can remove this when trashy gets support for macOS, which is blocked by an issue with the library they use
              # for accessing the trash: https://github.com/Byron/trash-rs/issues/8
              trash = prev.writeScriptBin "trash"
                ''
                  #!/usr/bin/env python3

                  import os
                  import sys
                  import subprocess

                  if len(sys.argv) > 1:
                      files = []
                      for arg in sys.argv[1:]:
                          if os.path.exists(arg):
                              p = os.path.abspath(arg).replace('\\', '\\\\').replace('"', '\\"')
                              files.append('the POSIX file "' + p + '"')
                          else:
                              sys.stderr.write(
                                  "%s: %s: No such file or directory\n" % (sys.argv[0], arg))
                      if len(files) > 0:
                          cmd = ['osascript', '-e',
                                'tell app "Finder" to move {' + ', '.join(files) + '} to trash']
                          r = subprocess.call(cmd, stdout=open(os.devnull, 'w'))
                          sys.exit(r if len(files) == len(sys.argv[1:]) else 1)
                  else:
                      sys.stderr.write(
                          'usage: %s file(s)\n'
                          '       move file(s) to Trash\n' % os.path.basename(sys.argv[0]))
                      sys.exit(64) # matches what rm does on my system
                '';
            };

            allPackages = crossPlatformPackages // linuxOnlyPackages // darwinOnlyPackages;
          in
            allPackages;

        overlayOutput = {
          overlays.default = overlay;
        };
      in
        overlayOutput;
  }
