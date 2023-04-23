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
        homeDirectory ? "/home/${username}",
        # copy or symlink
        installMethod ? "symlink",
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
                extraSpecialArgs = { inherit hostName isGui nix-index-database username homeDirectory installMethod; };
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
            hostName = "apps-default";
            homeManagerOutputs = createHomeManagerOutputs {
              inherit hostName;
              modules = [ ./.meta/modules/profile/system-administration.nix ];
              systems = [ system ];
              installMethod = "copy";
            };
            inherit (homeManagerOutputs.packages.${system}.homeConfigurations.${hostName}) activationPackage;
            # TODO: I would rather this be an overlay that I pass to home manager, but that results in an infinite loop
            # since the programs in here refer to the configuration files in home manager. Instead, I'll just
            # put them earlier on the PATH than the home manager programs. This results in duplicates of whatever
            # programs home manager and this have in common so I should find a way to remove those.
            sealedPackage = import ./.meta/modules/unit/sealed-packages.nix pkgs activationPackage;
            shellBootstrap = pkgs.writeScript "shell-bootstrap"
              ''
              #!${pkgs.fish}/bin/fish

              # My login shell .profile sets the LOCALE_ARCHIVE for me, but it sets it to
              # ~/.nix-profile/lib/locale/locale-archive and I won't have that in a 'sealed' environment so instead
              # I will source the Home Manager setup script because it sets the LOCALE_ARCHIVE to the path of the
              # archive in the Nix store.
              set --prepend fish_function_path ${pkgs.fishPlugins.foreign-env}/share/fish/vendor_functions.d
              fenv source ${activationPackage}/home-path/etc/profile.d/hm-session-vars.sh >/dev/null
              set -e fish_function_path[1]

              fish_add_path --global --prepend ${activationPackage}/home-path/bin
              fish_add_path --global --prepend ${sealedPackage}/bin
              fish_add_path --global --prepend ${activationPackage}/home-files/.local/bin

              # For packages that need one of its XDG Base directories to be mutable
              set -g mutable_bin (${pkgs.coreutils}/bin/mktemp --directory)
              fish_add_path --global --prepend ''$mutable_bin
              set -g state_dir (${pkgs.coreutils}/bin/mktemp --directory)
              set -g config_dir (${pkgs.coreutils}/bin/mktemp --directory)
              set -g data_dir (${pkgs.coreutils}/bin/mktemp --directory)

              # fish writes to its configuration directory so it needs to be mutable. So here I am copying
              # all of its config files from the Nix store to a mutable directory.
              ${pkgs.coreutils}/bin/cp --no-preserve=mode --recursive ${activationPackage}/home-files/.config/fish ''$config_dir
              # NOTE: The hashbang needs to be the first two bytes in the file for the kernel to recognize it so
              # don't move it to its own line.
              echo -s >''$mutable_bin/fish "#!${pkgs.fish}/bin/fish
                # I unexport the XDG Base directories so host programs pick up the host's XDG directories.
                XDG_CONFIG_HOME=''$config_dir XDG_DATA_HOME=''$data_dir XDG_STATE_HOME=''$state_dir ${pkgs.fish}/bin/fish \
                  --init-command 'set --unexport XDG_CONFIG_HOME' \
                  --init-command 'set --unexport XDG_DATA_HOME' \
                  --init-command 'set --unexport XDG_STATE_HOME'" ' ''$argv'
              ${pkgs.coreutils}/bin/chmod +x ''$mutable_bin/fish

              # neovim needs mutable directories as well
              ${pkgs.coreutils}/bin/cp --no-preserve=mode --recursive ${activationPackage}/home-files/.config/nvim ''$config_dir
              ${pkgs.coreutils}/bin/cp --no-preserve=mode --recursive ${activationPackage}/home-files/.local/share/nvim ''$data_dir
              # NOTE: The hashbang needs to be the first two bytes in the file for the kernel to recognize it so
              # don't move it to its own line.
              ${pkgs.coreutils}/bin/echo >''$mutable_bin/nvim "#!${pkgs.fish}/bin/fish
                XDG_CONFIG_HOME=''$config_dir XDG_DATA_HOME=''$data_dir XDG_STATE_HOME=''$state_dir ${pkgs.neovim-unwrapped}/bin/nvim
                "
              ${pkgs.coreutils}/bin/chmod +x ''$mutable_bin/nvim

              # Set fish as the default shell
              set --global --export SHELL ''$mutable_bin/fish

              # Compile my custom themes for bat.
              chronic bat cache --build

              exec ''$SHELL
              '';
          in
            {
              apps.default = {
                type = "app";
                program = builtins.toString shellBootstrap;
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
            # I want this script run by the shell output to be included in the build, but since it has no directory
            # associated with it (it's just /nix/<hash>-<script-name>) I can't include it in the `paths` key
            # of `symlinkJoin`. Instead, I copy it into the package created by `symlinkJoin` in the `postBuild` hook.
            copyShellOutputToPackage =
              if builtins.hasAttr system shellOutputsBySystem
                then ''cp ${shellOutputsBySystem.${system}.default.program} $out/''
                else "";
            homeManagerStorePaths =
              if builtins.hasAttr system activationPackagesBySystem
              then activationPackagesBySystem.${system}
              else [];
          in
            {
              packages = {
                "${system}" = {
                  default = pkgs.symlinkJoin
                    {
                      name ="default";
                      paths = homeManagerStorePaths;
                      postBuild = copyShellOutputToPackage;
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
