{
  inputs,
  self,
  ...
}: let
  moduleBaseDirectory = ./modules;

  # This is the module that I always include.
  baseModule = "${moduleBaseDirectory}/profile/base.nix";

  makeDarwinModules = {
    username,
    hostName,
    homeDirectory,
    repositoryDirectory,
    modules,
    isGui,
  }: let
    extraSpecialArgs = {
      # SYNC: EXTRA-SPECIAL-ARGS
      inherit hostName username homeDirectory repositoryDirectory isGui;
      isHomeManagerRunningAsASubmodule = true;
      flakeInputs = inputs;
    };
    configuration = {
      home-manager = {
        inherit extraSpecialArgs;
        useGlobalPkgs = true;
        # This makes home-manager install packages to the same path that it normally does, ~/.nix-profile. Though
        # this is the default now, they are considering defaulting to true later so I'm explicitly setting
        # it to false.
        useUserPackages = false;
        users.${username} = {
          imports = modules ++ [baseModule];
        };
      };
    };
  in [
    inputs.home-manager.darwinModules.home-manager
    configuration
  ];

  makeFlakeOutput = system: args @ {
    hostName,
    modules,
    isGui ? true,
    username ? "biggs",
    overlays ? [],
  }: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [self.overlays.default] ++ overlays;
    };
    homePrefix =
      if pkgs.stdenv.isLinux
      then "/home"
      else "/Users";
    homeDirectory =
      if builtins.hasAttr "homeDirectory" args
      then args.homeDirectory
      else "${homePrefix}/${username}";
    repositoryDirectory =
      if builtins.hasAttr "repositoryDirectory" args
      then args.repositoryDirectory
      else "${homeDirectory}/.dotfiles";
    extraSpecialArgs = {
      # SYNC: EXTRA-SPECIAL-ARGS
      inherit hostName isGui username homeDirectory repositoryDirectory;
      isHomeManagerRunningAsASubmodule = false;
      flakeInputs = inputs;
    };
  in {
    # Using `legacyPackages` here because `packages` doesn't support nested derivations meaning the values
    # inside the `packages` attribute set must be derivations.
    # For more info: https://discourse.nixos.org/t/flake-questions/8741/2
    legacyPackages.homeConfigurations.${hostName} = inputs.home-manager.lib.homeManagerConfiguration {
      modules = modules ++ [baseModule];
      inherit pkgs extraSpecialArgs;
    };
  };
in {
  flake = {
    lib.home = {
      inherit moduleBaseDirectory makeDarwinModules makeFlakeOutput;
    };
  };

  perSystem = {
    system,
    inputs',
    lib,
    ...
  }: let
    inherit (lib.attrsets) optionalAttrs;
    supportedSystems = with inputs.flake-utils.lib.system; [x86_64-linux x86_64-darwin];
    isSupportedSystem = builtins.elem system supportedSystems;
    initOutput = optionalAttrs isSupportedSystem {
      packages.homeManager = inputs'.home-manager.packages.default;
    };

    hosts = [
      {
        configuration = {
          hostName = "desktop";
          modules = [
            "${moduleBaseDirectory}/profile/application-development.nix"
            "${moduleBaseDirectory}/profile/system-administration.nix"
            "${moduleBaseDirectory}/profile/personal.nix"
          ];
        };
        systems = with inputs.flake-utils.lib.system; [
          x86_64-linux
        ];
      }
    ];
    isCurrentSystemSupportedByHost = host: builtins.elem system host.systems;
    supportedHosts = builtins.filter isCurrentSystemSupportedByHost hosts;
    makeFlakeOutputForHost = host: makeFlakeOutput system host.configuration;
    hostOutputs = map makeFlakeOutputForHost supportedHosts;

    mergedFlakeOutputs = self.lib.recursiveMerge (hostOutputs ++ [initOutput]);
  in
    mergedFlakeOutputs;
}
