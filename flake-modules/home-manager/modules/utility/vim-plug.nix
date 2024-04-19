{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types;
  # TODO: Workaround for this issue:
  # https://github.com/junegunn/vim-plug/issues/1135
  tweakedVimPlug =
    pkgs.runCommand
    "tweaked-plug.vim"
    {}
    ''
      vim_plug=${lib.strings.escapeShellArgs ["${pkgs.vimPlugins.vim-plug}/plug.vim"]}
      target="len(s:glob(s:rtp(a:plug), 'plugin'))"
      # First grep so the build will error out if the string isn't present
      grep -q "$target" "$vim_plug"
      sed -e "s@$target@v:true@" <"$vim_plug" >"$out"
    '';
in {
  options.vimPlug = {
    pluginFile = lib.mkOption {
      type = types.path;
    };
  };

  config = let
    pluginNames = builtins.filter (name: name != "") (lib.strings.splitString "\n" (builtins.readFile config.vimPlug.pluginFile));
    replaceDotsWithDashes = builtins.replaceStrings ["."] ["-"];
    pluginsByName = builtins.listToAttrs
      (map
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
        { name = pluginName; value = package; }
      )
      pluginNames);
  in {
    xdg.dataFile = {
      "nvim/site/autoload/plug.vim".source = "${tweakedVimPlug}";

      "nvim/site/lua/nix-plugins.lua".text = ''
        return {
          ${lib.strings.concatMapStringsSep "\n" (name: ''["${name}"] = "${builtins.getAttr name pluginsByName}",'') (builtins.attrNames pluginsByName)}
        }
      '';

      "nvim/site/parser".source = "${pkgs.vimPlugins.treesitter-parsers}/parser";
    };
  };
}
