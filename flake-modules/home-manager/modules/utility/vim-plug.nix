# This module will fetch all the vim plugins specified in a `plugfile.lua` and copy them to the directory
# where vim-plug stores plugins. This way you can fetch your plugins with Nix, but still load them with vim-plug.
# One advantage of this is that plugins can be stored in your Nix binary cache with all your other packages which
# is particularly useful for plugins that require compilation like nvim-treesitter.
#
# Caveats:
#   - You can only install and remove plugins with vim-plug. This is because all the other commands, like PlugDiff,
# depend on the plugin directory being a git repository and Nix doesn't include the .git folder when fetching a plugin.
# This is because the .git folder is not created deterministically so if it was included, the hash for the package
# may change despite fetching the same version. More info here: https://github.com/NixOS/nixpkgs/issues/8567.
#   - If you try to install nvim-treesitter grammars using TSInstall, you'll get an error. Not sure why, but this issue
# is acknowledged in the NixOS wiki: https://nixos.wiki/wiki/Treesitter.
{ config, lib, pkgs, ... }:
  let
    inherit (lib) types;
  in
    {
      options.vimPlug = {
        plugfile = lib.mkOption {
          type = types.path;
        };
      };

      config =
        let
          plugfile = builtins.readFile config.vimPlug.plugfile;
          plugfile_lines = builtins.filter (line: line != "") (lib.strings.splitString "\n" plugfile);
          pluginNames = map
            (line:
              let
                matches = builtins.match "RegisterPlug\\('.*/(.*)'\\)" line;
                pluginName = (builtins.elemAt matches 0);
              in
                pluginName
            )
            plugfile_lines;
          replaceDotsWithDashes = (builtins.replaceStrings ["."] ["-"]);
          formatPluginName = pluginName:
            lib.trivial.pipe
              pluginName
              [  lib.strings.toLower replaceDotsWithDashes ];
          packages = map
            (pluginName:
              let
                getPackageForPlugin = builtins.getAttr pluginName;
                formattedPluginName = (formatPluginName pluginName);
                package = if builtins.hasAttr pluginName pkgs.vimPlugins
                  then getPackageForPlugin pkgs.vimPlugins
                  else if builtins.hasAttr formattedPluginName pkgs.vimPlugins
                  then (builtins.getAttr "overrideAttrs" (builtins.getAttr formattedPluginName pkgs.vimPlugins)) (old: {pname = pluginName;})
                  else abort "Failed to find vim plugin: ${pluginName}";
              in
                package
            )
            pluginNames;
          pluginBundleName = "my-neovim-bundle";
          pluginBundlePackage = pkgs.vimUtils.packDir
            {
              "${pluginBundleName}" = {
                start = packages;
              };
            };
          pluginDirectoryRelativeToXdgDataHome = "nvim/plugged";
          pluginDirectory = "${config.xdg.dataHome}/${pluginDirectoryRelativeToXdgDataHome}";
          treesitter-parsers = pkgs.symlinkJoin {
            name = "treesitter-parsers";
            paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
          };
        in
          {
            xdg.dataFile = {
              "nvim/site/autoload/plug.vim".source = "${pkgs.vimPlugins.vim-plug}/plug.vim";
              "${pluginDirectoryRelativeToXdgDataHome}" = {
                source = "${pluginBundlePackage}/pack/${pluginBundleName}/start";
                recursive = true;
              };
              "nvim/site/parser".source = "${treesitter-parsers}/parser";
            };

            # Before we symlink the plugins, remove everything in the plugin directory.
            # TODO: Because of this, HM will print out an error when it tries to clean up an orphan link. This is because
            # the orphan link will have already been removed by this. So expect warning messages about orphan links
            # being skipped whenever you remove a plugin from neovim.
            home.activation.neovimSetup = lib.hm.dag.entryBefore
              [ "linkGeneration" ]
              ''
                if test -d "${pluginDirectory}" && test -n "$(ls -A "${pluginDirectory}")"; then
                  rm -rf ${pluginDirectory}/*  
                fi
              '';
            # broot.vim needs to write to its plugin directory so I'm going to dereference the symlink.
            home.activation.brootVimFix = lib.hm.dag.entryAfter
              [ "linkGeneration" ]
              ''
                broot_path='${pluginDirectory}/broot.vim'
                temp_broot_path="''$broot_path".temp

                cp --recursive --dereference --no-preserve=ownership "''$broot_path" "''$temp_broot_path"
                rm -rf "''$broot_path"
                # so I can move it
                chmod -R 777 "''$temp_broot_path"
                mv "''$temp_broot_path" "''$broot_path"
              '';
          };
    }
