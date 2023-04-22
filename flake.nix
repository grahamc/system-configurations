{
  description = "Biggs's Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    my-overlay.url = "path:./.meta/modules/my-overlay";
  };

  nixConfig = {
    extra-substituters = "https://bigolu.cachix.org";
    extra-trusted-public-keys = "bigolu.cachix.org-1:AJELdgYsv4CX7rJkuGu5HuVaOHcqlOgR07ZJfihVTIw=";
  };

  # TODO: Waiting on a more concise way to define configurations per system.
  # issue: https://github.com/nix-community/home-manager/issues/3075
  outputs = { nixpkgs, home-manager, nix-index-database, flake-utils, my-overlay, ... }:
    let
      createHomeManagerOutputs = {
        hostName,
        modules,
        systems,
        isGui ? false,
        username ? "biggs",
        homeDirectory ? "/home/${username}"
      }:
        flake-utils.lib.eachSystem
        systems
        (system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ my-overlay.overlays.default ];
            };
          in
            {
              packages.homeConfigurations.${hostName} = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                modules = modules ++ [ ./.meta/modules/profile/common.nix ];
                extraSpecialArgs = { inherit hostName isGui nix-index-database username homeDirectory; };
              };
            }
        );
      hostConfigurations = with flake-utils.lib.system;
        [
          {
            hostName = "laptop";
            modules = [
              ./.meta/modules/profile/application-development.nix
              ./.meta/modules/profile/system-administration.nix
              ./.meta/modules/profile/linux-desktop.nix
            ];
            systems = [ x86_64-linux ];
            isGui = true;
          }
          {
            hostName = "desktop";
            modules = [
              ./.meta/modules/profile/application-development.nix
              ./.meta/modules/profile/system-administration.nix
              ./.meta/modules/profile/linux-desktop.nix
            ];
            systems = [ x86_64-linux ];
            isGui = true;
          }
          {
            hostName = "macbook";
            modules = [
              ./.meta/modules/profile/application-development.nix
              ./.meta/modules/profile/system-administration.nix
            ];
            systems = [ x86_64-darwin ];
            isGui = true;
            username = "bigmac";
          }
        ];
      homeManagerOutputsPerHost = map createHomeManagerOutputs hostConfigurations;
      # e.g. {x86_64-linux = [<derivation>]; x86_64-darwin = [<derivation>];}
      activationPackagesBySystem = nixpkgs.lib.foldAttrs
        (item: acc:
          let
            configs = builtins.attrValues item.homeConfigurations;
            activationPackages = map (builtins.getAttr "activationPackage") configs;
          in
            acc ++ activationPackages
        )
        []
        (map (builtins.getAttr "packages") homeManagerOutputsPerHost);
      # Run my shell environment, both programs and their config files, completely from the nix store.
      shellOutputs = flake-utils.lib.eachSystem
        (with flake-utils.lib.system; [ x86_64-linux x86_64-darwin ])
        (system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ my-overlay.overlays.default ];
            };
            homeManagerConfiguration = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [ ./.meta/modules/profile/common.nix ./.meta/modules/profile/system-administration.nix ];
              extraSpecialArgs = { inherit nix-index-database; isGui = false; hostName = ""; };
            };
            activationPackage = homeManagerConfiguration.activationPackage;
            sealedPackage = import ./.meta/modules/unit/sealed-packages.nix pkgs activationPackage;
            fishWrapper = pkgs.symlinkJoin {
              name = "biggie-fish";
              paths = [ pkgs.fish ];
              buildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                wrapProgram $out/bin/fish \
                  --add-flags '--init-command' \
                  --add-flags "'fish_add_path --global --prepend ${activationPackage}/home-files/.local/bin'" \
                  --add-flags '--init-command' \
                  --add-flags "'fish_add_path --global --prepend ${activationPackage}/home-path/bin'" \
                  --add-flags '--init-command' \
                  --add-flags "'fish_add_path --global --prepend ${sealedPackage}/bin'" \
                  --add-flags '--init-command' \
                  --add-flags "'fish_add_path --global --prepend $out/bin'" \
                  --add-flags '--init-command' \
                  --add-flags "'chronic bat cache --build'" \
              '';
            };
          in
            {
              apps.default = {
                type = "app";
                program = "${fishWrapper}/bin/fish";
              };
            }
        );
      # The default output is a `symlinkJoin` of all the Home Manager outputs. This way I can easily build
      # all the Home Manager outputs in CI to populate my binary cache. There are some open issues for providing an
      # easier way to build all packages for CI.
      # issue: https://github.com/NixOS/nix/issues/7165
      # issue: https://github.com/NixOS/nix/issues/7157
      defaultOutputs = map
        (system:
          let
            pkgs = import nixpkgs {inherit system;};
            shellOutputsBySystem = shellOutputs.apps;
            shellStorePath =
              if builtins.hasAttr system shellOutputsBySystem
              then [(pkgs.lib.strings.removeSuffix "/bin/fish" shellOutputsBySystem.${system}.default.program)]
              else [];
            homeManagerStorePaths =
              if builtins.hasAttr system activationPackagesBySystem
              then activationPackagesBySystem.${system}
              else [];
            allPaths = homeManagerStorePaths ++ shellStorePath;
          in
            {
              packages = {
                "${system}" = {
                  default = pkgs.symlinkJoin
                    {
                      name ="default";
                      paths = allPaths;
                    };
                };
              };
            }
        )
        flake-utils.lib.allSystems;
      recursiveMerge = sets: nixpkgs.lib.lists.foldr nixpkgs.lib.recursiveUpdate {} sets;
    in
      # For example, merging these two sets:                                    Would result in one set containing:
      #  { packages = {                   { packages = {                          { packages = {
      #      x86_64-linux = {                 x86_64-linux = {                        x86_64-linux = {
      #        homeConfigurations = {           homeConfigurations = {                  homeConfigurations = {
      #          laptop = <derivation>;            desktop = <derivation>;                   laptop = <derivation>;
      #                                                                                     desktop = <derivation>;
      #        }                                }                                       }
      #      };                               };                                      };
      #    };                               };                                      };
      #  }                                }                                       }
      recursiveMerge (homeManagerOutputsPerHost ++ defaultOutputs ++ [shellOutputs]);
}
