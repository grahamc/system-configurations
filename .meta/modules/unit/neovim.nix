{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      makeSymlinkToRepo
      makeSymlinksToTopLevelFilesInRepo
      runBeforeLinkGeneration
      ;
    plugfile = builtins.readFile ../../../neovim/plugfile.lua;
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
            else abort "Failed to find vim plug ${pluginName}";
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
      home.packages = [
        pkgs.neovim-unwrapped
      ];

      xdg.configFile = makeSymlinksToTopLevelFilesInRepo "nvim" "neovim" ../../../neovim;

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
      home.activation.neovimSetup = runBeforeLinkGeneration ''
        if test -d "${pluginDirectory}" && test -n "$(ls -A "${pluginDirectory}")"; then
          rm -rf ${pluginDirectory}/*  
        fi
      '';
    }
