{
  inputs,
  self,
  ...
}: {
  perSystem = {
    lib,
    system,
    pkgs,
    ...
  }: let
    inherit (lib.attrsets) optionalAttrs;
    supportedSystems = with inputs.flake-utils.lib.system; [x86_64-linux x86_64-darwin];
    isSupportedSystem = builtins.elem system supportedSystems;
    makeShell = import ./make-shell;

    portableHomeOutputs = let
      shellBootstrap = makeShell {
        isGui = false;
        inherit pkgs self;
      };
      terminalBootstrapScriptName = "terminal";
      terminalBootstrap = let
        GUIShellBootstrap = makeShell {
          isGui = true;
          inherit pkgs self;
        };
      in
        pkgs.writeScriptBin
        terminalBootstrapScriptName
        ''
          #!${pkgs.bash}/bin/bash

          set -o errexit
          set -o nounset
          set -o pipefail

          exec ${GUIShellBootstrap}/bin/shell -c 'wezterm --config '"'"'font_locator="ConfigDirsOnly"'"'"' --config '"'"'font_dirs={"${pkgs.myFonts}"}'"'"' --config '"'"'default_prog={"'$SHELL'"}'"'"
        '';
    in {
      apps = {
        shell = {
          type = "app";
          program = "${shellBootstrap}/bin/shell";
        };
        terminal = {
          type = "app";
          program = "${terminalBootstrap}/bin/${terminalBootstrapScriptName}";
        };
      };

      packages = {
        shell = shellBootstrap;
        terminal = terminalBootstrap;
      };
    };
  in
    optionalAttrs isSupportedSystem portableHomeOutputs;
}
