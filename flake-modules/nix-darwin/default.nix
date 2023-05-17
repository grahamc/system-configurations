{ self, inputs, lib, ... }:
  {
    perSystem = {system, ...}:
      let
        makeFlakeOutput = {
          hostName,
          modules,
          homeModules,
          username ? "biggs",
          homeDirectory ? "/Users/${username}",
          repositoryDirectory ? "${homeDirectory}/.dotfiles",
        }:
          let
            homeManagerSubmodules = self.lib.makeDarwinModules
              {
                inherit username hostName homeDirectory repositoryDirectory;
                modules = homeModules;
                isGui = true;
              };
            overlayModule = {
              nixpkgs.overlays = [
                self.overlays.default
              ];
            };
            darwinConfiguration = inputs.nix-darwin.lib.darwinSystem
              {
                inherit system;
                modules = modules ++ homeManagerSubmodules ++ [overlayModule];
                specialArgs = {
                  inherit hostName username homeDirectory repositoryDirectory;
                  flakeInputs = inputs;
                };
              };
            darwinOutput = {
              # Using `legacyPackages` here because `packages` doesn't support nested derivations meaning the values
              # inside the `packages` attribute set must be derivations.
              # For more info: https://discourse.nixos.org/t/flake-questions/8741/2
              legacyPackages.darwinConfigurations.${hostName} = darwinConfiguration;
            };
          in
            darwinOutput;

        hosts =  [
          {
            configuration = {
              hostName = "bigmac";
              modules = [
                ./modules/general.nix
              ];
              homeModules = with self.lib.modules; [
                profile.system-administration
                profile.application-development
              ];
            };
            systems = with inputs.flake-utils.lib.system; [
              x86_64-darwin
            ];
          }
        ];
        isCurrentSystemSupportedByHost = host: builtins.elem system host.systems;
        supportedHosts = builtins.filter isCurrentSystemSupportedByHost hosts;
        makeFlakeOutputForHost = host: makeFlakeOutput host.configuration;
        flakeOutputs = map makeFlakeOutputForHost supportedHosts;
        mergedFlakeOutputs = self.lib.recursiveMerge flakeOutputs;
      in
        mergedFlakeOutputs;
  }
