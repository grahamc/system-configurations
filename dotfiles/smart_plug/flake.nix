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
              # Not exactly sure why, but the script only works when I'm in this directory. Probably something to do with
              # how I'm importing smart_plug.py
              cd ${self}/linux
              # I'm using exec so the python process will be the root process in the cgroup for the systemd service
              # and not this shell. This way it will receive any signals sent by systemd, for example SIGTERM
              # when I stop the service. Without exec, the SIGTERM listener in the python script wasn't working
              # properly.
              exec python smart-plug-daemon.py
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
