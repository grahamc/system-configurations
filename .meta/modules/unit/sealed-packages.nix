nixpkgs: activationPackage:
  let
    activationPackageHome = "${activationPackage}/home-files";
    makeSealedWrapper = {
      package,
      binaryPath ? null,
      environmentVariables ? {},
      flags ? []
    }:
      let
        name = nixpkgs.lib.strings.getName package;
        nonNullBinaryPath = if binaryPath == null
          then "bin/${name}"
          else binaryPath;
        defaultEnvironmentVariables = {
          XDG_CONFIG_HOME = "${activationPackageHome}/.config";
          XDG_DATA_HOME = "${activationPackageHome}/.local/share";
          XDG_STATE_HOME = "${activationPackageHome}/.local/state";
        };
        allEnvironmentVariables = defaultEnvironmentVariables // environmentVariables;
        joinedEnvironmentVariables = nixpkgs.lib.strings.concatMapStringsSep
          " "
          (environmentVariableName:
            let
              environmentVariableValue = allEnvironmentVariables.${environmentVariableName};
            in
              "--set ${environmentVariableName} ${environmentVariableValue}"
          )
          (builtins.attrNames allEnvironmentVariables);
        joinedFlags = nixpkgs.lib.strings.concatMapStringsSep
          " "
          (flag: "--add-flags ${flag}")
          flags;
        wrapper = nixpkgs.symlinkJoin {
          name = "${name}-wrapper";
          paths = [ package ];
          buildInputs = [ nixpkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/${nonNullBinaryPath} ${joinedFlags} ${joinedEnvironmentVariables}
          '';
        };
      in
        wrapper;
    sealedPackageConfigurations = [
      { package = nixpkgs.bat; }
      { package = nixpkgs.tmux; }
      { package = nixpkgs.nix; }
      { package = nixpkgs.lsd; }
      { package = nixpkgs.viddy; }
      { package = nixpkgs.less; }
      { package = nixpkgs.git; }
      { package = nixpkgs.delta; }
      { package = nixpkgs.gitui; }

      {
        package = nixpkgs.ripgrep;
        binaryPath = "bin/rg";
        environmentVariables = {
          RIPGREP_CONFIG_PATH = "${activationPackageHome}/.ripgreprc";
        };
      }
      {
        package = nixpkgs.watchman;
        environmentVariables = {
          WATCHMAN_CONFIG_FILE = "${activationPackageHome}/.config/watchman/watchman.json";
        };
      }
      {
        package = nixpkgs.figlet;
        environmentVariables = {
          FIGLET_FONTDIR = "${activationPackageHome}/.local/share/figlet";
        };
      }
    ] ++ nixpkgs.lib.lists.optionals nixpkgs.stdenv.isLinux [
      { package = nixpkgs.pipr; }
    ];
    sealedPackages = map makeSealedWrapper sealedPackageConfigurations;
    joinedPackage = nixpkgs.symlinkJoin {
      name = "sealed-packages";
      paths = sealedPackages;
    };
  in
    joinedPackage
