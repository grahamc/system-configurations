{ self, inputs, ... }:
  {
    perSystem = {system, ...}:
      let
        makeOutput = {
          hostName,
          modules,
          homeModules,
          username ? "biggs",
          homeDirectory ? "/Users/${username}",
          repositoryDirectory ? "${homeDirectory}/.dotfiles",
        }:
          let
            homeManagerModules = self.darwinModules.createHomeModules
              {
                inherit username hostName homeDirectory repositoryDirectory homeModules;
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
                modules = modules ++ homeManagerModules ++ [overlayModule];
                specialArgs = {
                  inherit hostName username homeDirectory repositoryDirectory;
                  inherit (self.otherlib) updateFlags;
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

        hosts = with inputs.flake-utils.lib.system; with self.darwinModules.homeModules;
          [
            {
              configuration = {
                hostName = "bigmac";
                modules = [
                  ../system/darwin/nix-darwin-modules/general.nix
                ];
                homeModules = [
                  profile.system-administration
                  profile.application-development
                ];
              };
              systems = [ x86_64-darwin ];
            }
          ];
        supportedHosts = builtins.filter
          (host: builtins.elem system host.systems)
          hosts;
        outputs = map
          (host: makeOutput host.configuration)
          supportedHosts;
        mergedOutputs = self.lib.recursiveMerge outputs;
      in
        mergedOutputs;
  }
