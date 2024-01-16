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

    scriptText = let
      projectRootDirectory = "${self}/dotfiles/smart_plug";
    in
      if isLinux
      then ''
        # Not exactly sure why, but the script only works when I'm in this directory. Probably something to do with
        # how I'm importing smart_plug.py
        cd ${projectRootDirectory}/linux
        # I'm using exec so the python process will be the root process in the cgroup for the systemd service
        # and not this shell. This way it will receive any signals sent by systemd, for example SIGTERM
        # when I stop the service. Without exec, the SIGTERM listener in the python script wasn't working
        # properly.
        exec python smart-plug-daemon.py
      ''
      else ''
        python ${projectRootDirectory}/smart_plug.py "$@"
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
