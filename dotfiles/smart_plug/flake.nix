{
  description = "Smart plug";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem
      (with flake-utils.lib.system; [ x86_64-linux x86_64-darwin ])
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pythonPackages = ps: with ps; [
            pip
            python-kasa
            diskcache
            ipython
            platformdirs
            psutil
          ] ++ pkgs.lib.lists.optionals pkgs.stdenv.isLinux [
            dbus-python
            pygobject3
          ];
          pythonWithPackages = pkgs.python3.withPackages pythonPackages;
          scriptText = if pkgs.stdenv.isLinux
            then ''
              python ${self}/linux/smart-plug-daemon.py
            ''
            else ''
              python ${self}/smart_plug.py "$@"
            '';
          cli = pkgs.writeShellApplication
            {
              name = "speakerctl";
              runtimeInputs = [pythonWithPackages];
              text = scriptText;
            };
        in {
          devShells.default = pkgs.mkShell { packages = [pythonWithPackages]; };
          packages.default = cli;
        }
      );
}
