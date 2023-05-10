{ lib, inputs, self, ... }:
  {
    flake =
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
              (result: basename: type:
                let
                  path = (directory + "/${basename}");
                  removeDotNixSuffix = basename: lib.strings.removeSuffix ".nix" basename;
                  modules = if isDirectory type
                    then { "${basename}" = loadModules path; }
                    else { "${removeDotNixSuffix basename}" = import path; };
                in
                  result // modules
              )
              {}
              filteredDirectoryContents;
            in
              modules;
        modules = loadModules ../home/home-manager-modules;
        homeSubmoduleOutputs = {
          darwinModules = {
            createHomeModules = {username, hostName, homeDirectory, repositoryDirectory, homeModules, isGui}:
              [
                inputs.home-manager.darwinModules.home-manager
                {
                  home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                  home-manager.extraSpecialArgs = {
                    inherit hostName username homeDirectory repositoryDirectory isGui;
                    inherit (inputs) nix-index-database;
                    inherit (self.lib) updateFlags;
                    isHomeManagerRunningAsASubmodule = true;
                  };
                  home-manager.users.${username} = {
                    imports = homeModules ++ [modules.profile.common];
                  };
                }
              ];
            homeModules = modules;
          };
        };

        createHomeOutput = system: args@{
          hostName,
          modules,
          isGui ? true,
          username ? "biggs",
        }:
          let
            pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [self.overlays.default];
            };
            homePrefix = if pkgs.stdenv.isLinux
              then "/home"
              else "/Users";
            homeDirectory = if builtins.hasAttr "homeDirectory" args
              then args.homeDirectory
              else "${homePrefix}/${username}";
            repositoryDirectory = if builtins.hasAttr "repositoryDirectory" args
              then args.repositoryDirectory
              else "${homeDirectory}/.dotfiles";
          in
            {
              # Using `legacyPackages` here because `packages` doesn't support nested derivations meaning the values
              # inside the `packages` attribute set must be derivations.
              # For more info: https://discourse.nixos.org/t/flake-questions/8741/2
              legacyPackages.homeConfigurations.${hostName} = inputs.home-manager.lib.homeManagerConfiguration {
                modules = modules ++ [self.darwinModules.homeModules.profile.common];
                inherit pkgs;
                extraSpecialArgs = {
                  inherit hostName isGui username homeDirectory repositoryDirectory;
                  inherit (inputs) nix-index-database;
                  inherit (self.lib) updateFlags;
                  isHomeManagerRunningAsASubmodule = false;
                };
              };
            };
        libOutputs = {
          lib = {
            inherit recursiveMerge createHomeOutput;
          };
        };
      in
        recursiveMerge [homeSubmoduleOutputs libOutputs];

    perSystem = {system, ...}:
      let
        hosts = with inputs.flake-utils.lib.system; with self.darwinModules.homeModules;
          [
            {
              configuration = {
                hostName = "laptop";
                modules = [
                  profile.application-development
                  profile.system-administration
                  gnome-theme-fix
                ];
              };
              systems = [ x86_64-linux ];
            }
            {
              configuration = {
                hostName = "desktop";
                modules = [
                  profile.application-development
                  profile.system-administration
                  gnome-theme-fix
                ];
              };
              systems = [ x86_64-linux ];
            }
          ];
        supportedHosts = builtins.filter
          (host: builtins.elem system host.systems)
          hosts;
        homeOutputs = map (host: self.lib.createHomeOutput system host.configuration) supportedHosts;
        mergedHomeOutputSet = self.lib.recursiveMerge homeOutputs;
      in
        mergedHomeOutputSet;
  }
