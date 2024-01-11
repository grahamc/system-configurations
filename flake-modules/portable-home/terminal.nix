{inputs, ...}: {
  perSystem = {
    lib,
    system,
    pkgs,
    self',
    ...
  }: let
    inherit (lib.attrsets) optionalAttrs;
    supportedSystems = with inputs.flake-utils.lib.system; [x86_64-linux x86_64-darwin];
    isSupportedSystem = builtins.elem system supportedSystems;

    terminalOutputs = let
      terminalBootstrapScriptName = "terminal";
      terminalBootstrap =
        pkgs.writeScriptBin
        terminalBootstrapScriptName
        ''
          #!${pkgs.bash}/bin/bash

          set -o errexit
          set -o nounset
          set -o pipefail

          exec ${pkgs.wezterm}/bin/wezterm \
            --config-file ${inputs.self.outPath}/dotfiles/wezterm/wezterm.lua \
            --config 'font_locator="ConfigDirsOnly"' \
            --config 'font_dirs={"${pkgs.myFonts}"}' \
            start \
            -- \
            ${self'.apps.shell.program}
        '';
    in {
      apps = {
        terminal = {
          type = "app";
          program = "${terminalBootstrap}/bin/${terminalBootstrapScriptName}";
        };
      };

      packages = {
        terminal = terminalBootstrap;
      };
    };
  in
    optionalAttrs isSupportedSystem terminalOutputs;
}
