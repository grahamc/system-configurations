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

    isSupportedSystem = let
      supportedSystems = with inputs.flake-utils.lib.system; [x86_64-linux x86_64-darwin];
    in
      builtins.elem system supportedSystems;

    portableHomeOutputs = let
      makePortableHome = {
        isGui,
        isMinimal,
      }:
        import ./make-portable-home {
          inherit pkgs self isGui isMinimal;
        };

      makeShell = {isMinimal}:
        makePortableHome {
          isGui = false;
          inherit isMinimal;
        };

      makeTerminal = {isMinimal}: let
        portableHome = makePortableHome {
          isGui = true;
          inherit isMinimal;
        };
      in
        pkgs.writeScriptBin
        "terminal"
        ''
          #!${pkgs.bash}/bin/bash

          set -o errexit
          set -o nounset
          set -o pipefail

          exec ${lib.getExe portableHome} -c 'exec wezterm --config "font_locator=[[ConfigDirsOnly]]" --config "font_dirs={[[${pkgs.myFonts}]]}" --config "default_prog={[[$SHELL]]}" --config "set_environment_variables={SHELL=[[$SHELL]]}"'
        '';
    in {
      packages = {
        shell = makeShell {isMinimal = false;};
        shellMinimal = makeShell {isMinimal = true;};
        terminal = makeTerminal {isMinimal = false;};
        terminalMinimal = makeTerminal {isMinimal = true;};
      };
    };
  in
    optionalAttrs isSupportedSystem portableHomeOutputs;
}
