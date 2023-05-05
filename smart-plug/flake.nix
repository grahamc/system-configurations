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
          pythonPackageDependencies = with pkgs.python310Packages; [
            pygobject3
            pip
            dbus-python
            python-kasa
          ];
          allDependencies = [ pkgs.python310Full ] ++ pythonPackageDependencies;
          cli = pkgs.writeShellApplication
            {
              name = "smart-plug";
              runtimeInputs = allDependencies;
              text = "python ${self}/smart-plug-daemon.py";
            };
        in {
          devShells.default = pkgs.mkShell { packages = allDependencies; };
          apps.default = {
            type = "app";
            program = "${cli}/bin/smart-plug";
          };
          legacyPackages.homeManagerModules.smart-plug = { config, lib, specialArgs, ... }:
            lib.mkIf
              specialArgs.isGui
              {
                systemd.user.services = {
                  smart-plug = {
                    Unit = {
                      Description = "Toggle smart plug";
                    };
                    Service = {
                      ExecStart = "${cli}/bin/smart-plug";
                    };
                    Install = {
                      WantedBy = ["multi-user.target"];
                    };
                  };
                };
              };
        }
      );
}
