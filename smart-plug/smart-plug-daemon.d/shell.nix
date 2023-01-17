{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/2f9fd351ec37f5d479556cd48be4ca340da59b8f.tar.gz") {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.python310Full
    pkgs.python310Packages.pygobject3
    pkgs.python310Packages.pip
    pkgs.python310Packages.dbus-python
    pkgs.python310Packages.python-kasa
  ];
}
