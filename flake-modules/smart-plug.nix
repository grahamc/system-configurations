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

    outputs = {
      packages.smartPlug = cli;

      # The devShell contains a lot of environment variables that are irrelevant
      # to our development environment, but Nix is working on a solution to
      # that: https://github.com/NixOS/nix/issues/7501
      devShells.smartPlug = pkgs.mkShellNoCC {
        packages = [
          pythonWithPackages
        ];
      };
    };

    supportedSystems = with inputs.flake-utils.lib.system; [x86_64-linux x86_64-darwin];
    isSupportedSystem = builtins.elem system supportedSystems;
  in
    optionalAttrs isSupportedSystem outputs;
}
