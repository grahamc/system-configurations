# This module will read all the config files in `config.vimPlug.configDirectory`, fetch the plugins specified in them,
# and copy them to the directory where vim-plug stores plugins. This way you can fetch your plugins with Nix, but
# still load them with vim-plug. One advantage of this is that plugins can be stored in your Nix binary cache with
# all your other packages which is particularly useful for plugins that require compilation like nvim-treesitter.
#
# Caveats:
#   - You can only install and remove plugins with vim-plug. This is because all the other commands, like PlugDiff,
# depend on the plugin directory being a git repository and Nix doesn't include the .git folder when fetching a plugin.
# This is because the .git folder is not created deterministically so if it was included, the hash for the package
# may change despite fetching the same version. More info here: https://github.com/NixOS/nixpkgs/issues/8567.
#   - If you try to install nvim-treesitter grammars using TSInstall, you'll get an error. Not sure why, but this issue
# is acknowledged in the NixOS wiki: https://nixos.wiki/wiki/Treesitter.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types;
in {
  options.vimPlug = {
    pluginFile = lib.mkOption {
      type = types.path;
    };
  };

  config = let
    pluginNames = lib.strings.splitString "\n" (builtins.readFile config.vimPlug.pluginFile);
    replaceDotsWithDashes = builtins.replaceStrings ["."] ["-"];
    plugins =
      map
      (
        pluginName: let
          getPackageForPlugin = builtins.getAttr pluginName;
          formattedPluginName = replaceDotsWithDashes pluginName;
          package =
            if builtins.hasAttr pluginName pkgs.vimPlugins
            then getPackageForPlugin pkgs.vimPlugins
            else if builtins.hasAttr formattedPluginName pkgs.vimPlugins
            then (builtins.getAttr "overrideAttrs" (builtins.getAttr formattedPluginName pkgs.vimPlugins)) (_old: {pname = pluginName;})
            else abort "Failed to find vim plugin: ${pluginName}";
        in
          package
      )
      pluginNames;
    pluginBundleName = "my-neovim-bundle";
    pluginBundlePackage =
      pkgs.vimUtils.packDir
      {
        "${pluginBundleName}" = {
          start = plugins;
        };
      };
    pluginDirectoryRelativeToXdgDataHome = "nvim/plugged";
    pluginDirectory = "${config.xdg.dataHome}/${pluginDirectoryRelativeToXdgDataHome}";
    treesitter-parsers = pkgs.symlinkJoin {
      name = "treesitter-parsers";
      paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
    };
  in {
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
    home.activation.neovimSetup =
      lib.hm.dag.entryBefore
      ["linkGeneration"]
      ''
        if test -d "${pluginDirectory}" && test -n "$(ls -A "${pluginDirectory}")"; then
          rm -rf ${pluginDirectory}/*
        fi
      '';
  };
}
