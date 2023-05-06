{
  description = "Smart plug";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem
      (with flake-utils.lib.system; [ x86_64-linux ])
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pythonPackages = ps: with ps; [
            pygobject3
            pip
            dbus-python
            python-kasa
          ];
          pythonWithPackages = pkgs.python3.withPackages pythonPackages;
          cli = pkgs.writeShellApplication
            {
              name = "smart-plug";
              runtimeInputs = [pythonWithPackages];
              text = "python ${self}/smart-plug-daemon.py";
            };
        in {
          devShells.default = pkgs.mkShell { packages = [pythonWithPackages]; };
          apps.default = {
            type = "app";
            program = "${cli}/bin/smart-plug";
          };
        }
      );
}
