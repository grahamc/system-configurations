{ self, inputs, lib, ... }:
  {
    perSystem = {system, ...}:
      let
        recursiveMerge = sets: lib.lists.foldr lib.recursiveUpdate {} sets;

        makeOutput = {
          hostName,
          modules,
          homeModules,
          username ? "biggs",
          homeDirectory ? "/Users/${username}",
          repositoryDirectory ? "${homeDirectory}/.dotfiles",
        }:
          let
            homeManagerSubmodules = self.home-manager-utilties.makeDarwinModules
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
                  inherit (self.input-utilities) updateFlags;
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
                ../system/darwin/nix-darwin-modules/general.nix
              ];
              homeModules = with self.home-manager-utilties.modules; [
                profile.system-administration
                profile.application-development
              ];
            };
            systems = with inputs.flake-utils.lib.system; [
              x86_64-darwin
            ];
          }
        ];
        supportedHosts = builtins.filter
          (host: builtins.elem system host.systems)
          hosts;
        outputs = map
          (host: makeOutput host.configuration)
          supportedHosts;
        mergedOutputs = recursiveMerge outputs;
      in
        mergedOutputs;
  }
