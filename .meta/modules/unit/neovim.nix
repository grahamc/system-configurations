{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
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
          # TODO: make a changepackaegname function
          package = if builtins.hasAttr pluginName pkgs.vimPlugins
            then getPackageForPlugin pkgs.vimPlugins
            else if builtins.hasAttr formattedPluginName pkgs.vimPlugins
            # TODO: name vs pname?
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

      home.file = {
        ".dotfiles/.meta/git_file_watch/active_file_watches/neovim".source = makeSymlinkToRepo ".meta/git_file_watch/file_watches/neovim.sh";
      };

      xdg.configFile = makeSymlinksToTopLevelFilesInRepo "nvim" "neovim";

      xdg.dataFile = {
        "nvim/site/autoload/plug.vim".source = "${pkgs.vimPlugins.vim-plug}/plug.vim";
        "${pluginDirectoryRelativeToXdgDataHome}" = {
          source = "${pluginBundlePackage}/pack/${pluginBundleName}/start";
          recursive = true;
        };
        "nvim/site/parser".source = "${treesitter-parsers}/parser";
      };

      # Before we symlink the plugins, remove everything in the plugin directory.
      home.activation.neovimSetup = runBeforeLinkGeneration ''
        if test -d "${pluginDirectory}" && test -n "$(ls -A "${pluginDirectory}")"; then
          rm ${pluginDirectory}/*  
        fi
      '';
    }
