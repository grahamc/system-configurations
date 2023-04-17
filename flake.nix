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

  # TODO: Waiting on a more concise way to define configurations per system.
  # issue: https://github.com/nix-community/home-manager/issues/3075
  outputs = { nixpkgs, home-manager, nix-index-database, flake-utils, my-overlay, ... }:
    let
      createConfigurations = {
        hostName,
        modules,
        systems,
        isGui ? false
      }:
        flake-utils.lib.eachSystem
        systems
        (system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [  my-overlay.overlays.default (import ./.meta/modules/overlay.nix) ];
            };
          in
            {
              packages.homeConfigurations.${hostName} = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                modules = modules ++ [ ./.meta/modules/profile/common.nix ];
                extraSpecialArgs = { inherit hostName isGui nix-index-database; };
              };
            }
        );
      hostConfigurations = map createConfigurations [
        {
          hostName = "server";
          modules = [
            ./.meta/modules/profile/system-administration.nix
          ];
          systems = (with flake-utils.lib.system; [ x86_64-linux ]);
        }
        {
          hostName = "laptop";
          modules = [
            ./.meta/modules/profile/application-development.nix
            ./.meta/modules/profile/system-administration.nix
            ./.meta/modules/profile/linux-desktop.nix
          ];
          systems = (with flake-utils.lib.system; [ x86_64-linux ]);
          isGui = true;
        }
        {
          hostName = "desktop";
          modules = [
            ./.meta/modules/profile/application-development.nix
            ./.meta/modules/profile/system-administration.nix
            ./.meta/modules/profile/linux-desktop.nix
          ];
          systems = (with flake-utils.lib.system; [ x86_64-linux ]);
          isGui = true;
        }
        {
          hostName = "macbook";
          modules = [
            ./.meta/modules/profile/application-development.nix
            ./.meta/modules/profile/system-administration.nix
          ];
          systems = (with flake-utils.lib.system; [ x86_64-darwin ]);
          isGui = true;
        }
      ];
      # Recursively merges a list of attribute sets
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
      #      aarch64-linux = {                aarch64-linux = {                       aarch64-linux = {
      #        homeConfigurations = {           homeConfigurations = {                  homeConfigurations = {
      #          laptop = <derivation>;            desktop = <derivation>;                   laptop = <derivation>;
      #                                                                                    desktop = <derivation>;
      #        }                                }                                       }
      #      };                               };                                      };
      #    };                               };                                      };
      #  }                                }                                       }
      recursiveMerge hostConfigurations;
}
