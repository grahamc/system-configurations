{ lib, inputs, self, ... }:
  let
    recursiveMerge = sets: lib.lists.foldr lib.recursiveUpdate {} sets;

    loadModules = directory:
      let
        directoryContents = builtins.readDir directory;
        isDirectory = type: type == "directory";
        isNixFile = basename: lib.strings.hasSuffix ".nix" basename;
        isNixFileOrDirectory = basename: type: isNixFile basename || isDirectory type;
        filteredDirectoryContents = lib.attrsets.filterAttrs
          isNixFileOrDirectory
          directoryContents;
        modules = lib.attrsets.foldlAttrs
          (accumulator: basename: type:
            let
              path = (directory + "/${basename}");
              removeDotNixSuffix = basename: lib.strings.removeSuffix ".nix" basename;
              modules = if isDirectory type
                then { "${basename}" = loadModules path; }
                else { "${removeDotNixSuffix basename}" = import path; };
            in
              accumulator // modules
          )
          {}
          filteredDirectoryContents;
        in
          modules;
    modules = loadModules ../home/home-manager-modules;

    defaultModules = [modules.profile.common];
    # I made this function to ensure that I pass the correct `extraSpecialArgs` when using home-manager
    # directly and as a submodule, since I sometimes add an argument to one and not the other. If I don't
    # pass the correct arguments Nix will throw an error since I didn't call the function with the specified
    # arguments.
    validateExtraSpecialArgs =
      args@{
        hostName,
        isGui,
        username,
        homeDirectory,
        repositoryDirectory,
        nix-index-database,
        stackline,
        updateFlags,
        isHomeManagerRunningAsASubmodule,
      }:
      args;

    makeDarwinModules = {username, hostName, homeDirectory, repositoryDirectory, modules, isGui}:
      let
        extraSpecialArgs = validateExtraSpecialArgs
          {
            inherit hostName username homeDirectory repositoryDirectory isGui;
            inherit (inputs) nix-index-database;
            inherit (inputs) stackline;
            inherit (self.input-utilities) updateFlags;
            isHomeManagerRunningAsASubmodule = true;
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
              imports = modules ++ defaultModules;
            };
          };
        };
      in
        [
          inputs.home-manager.darwinModules.home-manager
          configuration
        ];

    makeFlakeOutput =
      system: 
      args@{
        hostName,
        modules,
        isGui ? true,
        username ? "biggs",
        homeDirectory ? null,
        repositoryDirectory ? null,
      }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [self.overlays.default];
          };
          homePrefix = if pkgs.stdenv.isLinux
            then "/home"
            else "/Users";
          homeDirectory = if args.homeDirectory == null
            then "${homePrefix}/${username}"
            else args.homeDirectory;
          repositoryDirectory = if args.repositoryDirectory == null
            then "${homeDirectory}/.dotfiles"
            else args.repositoryDirectory;
          extraSpecialArgs = validateExtraSpecialArgs
            {
              inherit hostName isGui username homeDirectory repositoryDirectory;
              inherit (inputs) nix-index-database;
              inherit (inputs) stackline;
              inherit (self.input-utilities) updateFlags;
              isHomeManagerRunningAsASubmodule = false;
            };
        in
          {
            # Using `legacyPackages` here because `packages` doesn't support nested derivations meaning the values
            # inside the `packages` attribute set must be derivations.
            # For more info: https://discourse.nixos.org/t/flake-questions/8741/2
            legacyPackages.homeConfigurations.${hostName} = inputs.home-manager.lib.homeManagerConfiguration {
              modules = modules ++ defaultModules;
              inherit pkgs extraSpecialArgs;
            };
          };
  in
    {
      flake = {
        home-manager-utilties = {
          inherit modules makeDarwinModules makeFlakeOutput;
        };
      };

      perSystem = {system, ...}:
        let
          hosts = 
            [
              {
                configuration = {
                  hostName = "laptop";
                  modules = with modules; [
                    profile.application-development
                    profile.system-administration
                    gnome-theme-fix
                  ];
                };
                systems = with inputs.flake-utils.lib.system; [
                  x86_64-linux
                ];
              }
              {
                configuration = {
                  hostName = "desktop";
                  modules = with modules; [
                    profile.application-development
                    profile.system-administration
                    gnome-theme-fix
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
          flakeOutputs = map makeFlakeOutputForHost supportedHosts;
          mergedFlakeOutputs = recursiveMerge flakeOutputs;
        in
          mergedFlakeOutputs;
    }
