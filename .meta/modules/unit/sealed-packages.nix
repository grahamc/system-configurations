nixpkgs: activationPackage:
  let
    activationPackageHome = "${activationPackage}/home-files";
    makeSealedWrapper = {
      package,
      binaryPath ? "bin/${package.pname}",
      environmentVariables ? {},
      flags ? []
    }:
      let
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
          name = "${package.pname}-wrapper";
          paths = [ package ];
          buildInputs = [ nixpkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/${binaryPath} ${joinedFlags} ${joinedEnvironmentVariables}
          '';
        };
      in
        wrapper;
    sealedPackages = [
      (makeSealedWrapper { package = nixpkgs.bat; })
      (makeSealedWrapper { package = nixpkgs.tmux; })
      (makeSealedWrapper {
        package = nixpkgs.ripgrep;
        binaryPath = "bin/rg";
        environmentVariables = {
          RIPGREP_CONFIG_PATH = "${activationPackageHome}/.ripgreprc";
        };
      })
      (makeSealedWrapper { package = nixpkgs.lsd; })
      (makeSealedWrapper { package = nixpkgs.viddy; })
      (makeSealedWrapper {
        package = nixpkgs.watchman;
        environmentVariables = {
          WATCHMAN_CONFIG_FILE = "${activationPackageHome}/.config/watchman/watchman.json";
        };
      })
      (makeSealedWrapper { package = nixpkgs.less; })
      (makeSealedWrapper {
        package = nixpkgs.figlet;
        environmentVariables = {
          FIGLET_FONTDIR = "${activationPackageHome}/.local/share/figlet";
        };
      })
      (makeSealedWrapper { package = nixpkgs.nix; })

      # git
      (makeSealedWrapper { package = nixpkgs.git; })
      (makeSealedWrapper { package = nixpkgs.delta; })
      (makeSealedWrapper { package = nixpkgs.gitui; })
    ] ++ nixpkgs.lib.lists.optionals nixpkgs.stdenv.isLinux [
      (makeSealedWrapper { package = nixpkgs.pipr; })
    ];
    joinedPackage = nixpkgs.symlinkJoin {
      name = "sealed-packages";
      paths = sealedPackages;
    };
  in
    joinedPackage
