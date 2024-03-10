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
    inherit (pkgs.stdenv) isLinux;

    portableHomeOutputs = let
      shellBootstrap = makeShell {
        isGui = false;
        inherit pkgs self;
      };
      makeEmptyPackage = packageName: pkgs.runCommand packageName {} ''mkdir -p $out/bin'';
      shellMinimalName = "shell-minimal";
      shellMinimalBootstrap = makeShell {
        name = shellMinimalName;
        isGui = false;
        inherit pkgs self;
        modules = [
          {
            xdg.dataFile = {
              "nvim/site/parser" = lib.mkForce {
                source = makeEmptyPackage "parsers";
              };
            };
          }
        ];
        overlays = [
          (_final: _prev: {
            # to remove perl dependency
            moreutils = makeEmptyPackage "moreutils";

            ast-grep = makeEmptyPackage "ast-grep";
          })
        ];
      };
      terminalBootstrapScriptName = "terminal";
      terminalBootstrap = let
        GUIShellBootstrap = makeShell {
          isGui = true;
          inherit pkgs self;
        };
        nixgl =
          if isLinux
          then " ${pkgs.nixgl.auto.nixGLDefault}/bin/nixGL"
          else "";
      in
        pkgs.writeScriptBin
        terminalBootstrapScriptName
        ''
          #!${pkgs.bash}/bin/bash

          set -o errexit
          set -o nounset
          set -o pipefail

          exec ${GUIShellBootstrap}/bin/shell -c 'exec${nixgl} wezterm --config "font_locator=[[ConfigDirsOnly]]" --config "font_dirs={[[${pkgs.myFonts}]]}" --config "default_prog={[[$SHELL]]}" --config "set_environment_variables={SHELL=[[$SHELL]]}"'
        '';
    in {
      apps = {
        shell = {
          type = "app";
          program = "${shellBootstrap}/bin/shell";
        };
        shellMinimal = {
          type = "app";
          program = "${shellMinimalBootstrap}/bin/${shellMinimalName}";
        };
        terminal = {
          type = "app";
          program = "${terminalBootstrap}/bin/${terminalBootstrapScriptName}";
        };
      };

      packages = {
        shell = shellBootstrap;
        shellMinimal = shellMinimalBootstrap;
        terminal = terminalBootstrap;
      };
    };
  in
    optionalAttrs isSupportedSystem portableHomeOutputs;
}
