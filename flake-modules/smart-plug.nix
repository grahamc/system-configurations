{
  lib,
  inputs,
  self,
  ...
}: {
  perSystem = {
    system,
    pkgs,
    ...
  }: let
    inherit (lib.attrsets) optionalAttrs;
    inherit (pkgs.stdenv) isLinux;
    inherit (lib.lists) optionals;

    pythonPackages = ps:
      with ps;
        [
          pip
          python-kasa
          diskcache
          ipython
          platformdirs
          psutil
        ]
        ++ optionals isLinux [
          dbus-python
          pygobject3
        ];
    pythonWithPackages = pkgs.python3.withPackages pythonPackages;

    scriptText = ''
      python ${self}/dotfiles/smart_plug/smart_plug.py "$@"
    '';

    cli =
      pkgs.writeShellApplication
      {
        name = "speakerctl";
        runtimeInputs = [pythonWithPackages];
        text = scriptText;
      };

    profile = pkgs.symlinkJoin {
      name = "tools";
      paths = [
        pythonWithPackages
      ];
    };

    devShell = self.lib.devShell.mkNakedShell {
      name = "devShell";
      inherit profile pkgs;
    };

    outputs = {
      devShells.smartPlug = devShell;
      packages.smartPlug = cli;
    };

    supportedSystems = with inputs.flake-utils.lib.system; [x86_64-linux x86_64-darwin];
    isSupportedSystem = builtins.elem system supportedSystems;
  in
    optionalAttrs isSupportedSystem outputs;
}
