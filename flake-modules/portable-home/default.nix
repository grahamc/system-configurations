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
    makeEmptyPackage = packageName: pkgs.runCommand packageName {} ''mkdir -p $out/bin'';
    makeMinimalShell = {isGui ? false}:
      makeShell {
        inherit pkgs self isGui;
        modules = [
          {
            xdg = {
              dataFile = {
                "nvim/site/parser" = lib.mkForce {
                  source = makeEmptyPackage "parsers";
                };
              };
            };
          }
        ];
        overlays = [
          (_final: _prev: {
            moreutils = makeEmptyPackage "moreutils";
            ast-grep = makeEmptyPackage "ast-grep";
            timg = makeEmptyPackage "timg";
            ripgrep-all = makeEmptyPackage "ripgrep-all";
            lesspipe = makeEmptyPackage "lesspipe";
            wordnet = makeEmptyPackage "wordnet";
          })
        ];
      };
    makeTerminal = {isMinimal ? false}: let
      GUIShellBootstrap = (
        if isMinimal
        then makeMinimalShell
        else makeShell
      ) {isGui = true;};
    in
      pkgs.writeScriptBin
      "terminal"
      ''
        #!${pkgs.bash}/bin/bash

              set -o errexit
              set -o nounset
              set -o pipefail

              exec ${lib.getExe GUIShellBootstrap} -c 'exec wezterm --config "font_locator=[[ConfigDirsOnly]]" --config "font_dirs={[[${pkgs.myFonts}]]}" --config "default_prog={[[$SHELL]]}" --config "set_environment_variables={SHELL=[[$SHELL]]}"'
      '';

    portableHomeOutputs = let
      shellBootstrap = makeShell {
        isGui = false;
        inherit pkgs self;
      };
      shellMinimalBootstrap = makeMinimalShell {};
      terminalBootstrap = makeTerminal {};
      terminalMinimalBootstrap = makeTerminal {isMinimal = true;};
    in {
      packages = {
        shell = shellBootstrap;
        shellMinimal = shellMinimalBootstrap;
        terminal = terminalBootstrap;
        terminalMinimal = terminalMinimalBootstrap;
      };
    };
  in
    optionalAttrs isSupportedSystem portableHomeOutputs;
}
