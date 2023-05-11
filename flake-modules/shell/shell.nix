{ inputs, self, ... }:
  {
    perSystem = {lib, system, pkgs, ...}:
      let
        # Run my shell environment, both programs and their config files, completely from the nix store.
        supportedSystems = with inputs.flake-utils.lib.system; [ x86_64-linux x86_64-darwin ];
        isSupportedSystem = builtins.elem system supportedSystems;
        shellOutput = if !isSupportedSystem
          then
            null
          else
            let
              hostName = "no-host";
              homeManagerOutput = self.home-manager-utilties.makeHomeOutput system {
                inherit hostName;
                modules = with self.home-manager-utilties.modules; [
                  profile.system-administration
                  # I want a self contained executable so I can't have symlinks that point outside the Nix store.
                  {config.repository.symlink.makeCopiesInstead = true;}
                ];
                isGui = false;
              };
              inherit (homeManagerOutput.legacyPackages.homeConfigurations.${hostName}) activationPackage;
              # I don't want the programs that this script depends on to be in the $PATH since they are not
              # necessarily part of my Home Manager configuration so I'll set them to variables instead.
              mktemp = "${pkgs.coreutils}/bin/mktemp";
              copy = "${pkgs.coreutils}/bin/cp";
              chmod = "${pkgs.coreutils}/bin/chmod";
              fish = "${pkgs.fish}/bin/fish";
              coreutilsBinaryPath = "${pkgs.coreutils}/bin";
              basename = "${coreutilsBinaryPath}/basename";
              which = "${pkgs.which}/bin/which";
              foreignEnvFunctionPath = "${pkgs.fishPlugins.foreign-env}/share/fish/vendor_functions.d";
              shellBootstrapScriptName = "shell";
              shellBootstrapScript = import ./shell-bootstrap-script.nix
                {
                  inherit
                    activationPackage
                    mktemp
                    copy
                    chmod
                    fish
                    coreutilsBinaryPath
                    basename
                    which
                    foreignEnvFunctionPath
                    ;
                };
              shellBootstrap = pkgs.writeScriptBin shellBootstrapScriptName shellBootstrapScript;
            in
              {
                apps.default = {
                  type = "app";
                  program = "${shellBootstrap}/bin/${shellBootstrapScriptName}";
                };
                packages.shell = shellBootstrap;
              };
      in
        shellOutput;
  }
