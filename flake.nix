{
  description = "Biggs's Home Manager configuration";

  nixConfig = {
    extra-substituters = "https://bigolu.cachix.org";
    extra-trusted-public-keys = "bigolu.cachix.org-1:AJELdgYsv4CX7rJkuGu5HuVaOHcqlOgR07ZJfihVTIw=";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        utils.follows = "flake-utils";
      };
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    my-overlay.url = "path:./.meta/modules/my-overlay";
    nix-appimage = {
      url = "github:ralismark/nix-appimage";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    nix-xdg = {
      url = "github:infinisil/nix-xdg";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-index-database, flake-utils, my-overlay, nix-appimage, nix-xdg }:
    let
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
      recursiveMerge = sets: nixpkgs.lib.lists.foldr nixpkgs.lib.recursiveUpdate {} sets;
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
        # TODO: Waiting on a more concise way to define configurations per system.
        # issue: https://github.com/nix-community/home-manager/issues/3075
        flake-utils.lib.eachSystem
        systems
        (system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ my-overlay.overlays.default ];
            };

            xdgOverlay = ((import "${nix-xdg}/module.nix") {inherit pkgs; inherit (pkgs) lib; config = {};}).config.lib.xdg.xdgOverlay
              {
                specs = {
                  ripgrep.env.RIPGREP_CONFIG_PATH = {config}: "${config}/ripgreprc";
                  watchman.env.WATCHMAN_CONFIG_FILE = {config}: "${config}/watchman.json";
                  figlet.env.FIGLET_FONTDIR = {data}: data;
                };
              };
            xdgPkgs = import nixpkgs {
              inherit system;
              overlays = [ xdgOverlay ];
            };
          in
            {
              # Using `legacyPackages` here because `packages` doesn't support nested derivations meaning the values
              # inside the `packages` attribute set must be derivations.
              # For more info: https://discourse.nixos.org/t/flake-questions/8741/2
              legacyPackages.homeConfigurations.${hostName} = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                modules = modules ++ [ ./.meta/modules/profile/common.nix ];
                extraSpecialArgs = { inherit hostName isGui nix-index-database username homeDirectory installMethod xdgPkgs; };
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
            hostName = "bigmac";
            modules = [
              ./.meta/modules/profile/application-development.nix
              ./.meta/modules/profile/system-administration.nix
            ];
            systems = [ x86_64-darwin ];
            isGui = true;
            homeDirectory = "/Users/biggs";
          }
        ];
      homeManagerOutputsPerHost = map createHomeManagerOutputs hostConfigurations;
      homeManagerOutputs = recursiveMerge homeManagerOutputsPerHost;
      # Run my shell environment, both programs and their config files, completely from the nix store.
      shellOutputs = flake-utils.lib.eachSystem
        (with flake-utils.lib.system; [ x86_64-linux x86_64-darwin ])
        (system:
          let
            pkgs = import nixpkgs { inherit system; };
            hostName = "apps-default";
            homeManagerOutputs = createHomeManagerOutputs {
              inherit hostName;
              modules = [ ./.meta/modules/profile/system-administration.nix ];
              systems = [ system ];
              installMethod = "copy";
            };
            inherit (homeManagerOutputs.legacyPackages.${system}.homeConfigurations.${hostName}) activationPackage;
            shellBootstrapScriptName = "shell";
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
            # I couldn't figure out how to escape '$argv' properly in a double quoted string in the fish wrapper so
            # I'm using a single quoted string and having echo concatenate it with everything else.
            #
            # NOTE: The hashbangs in the scripts need to be the first two bytes in the file for the kernel to
            # recognize them so it must come directly after the opening quote of the script.
            shellBootstrap = pkgs.writeScriptBin shellBootstrapScriptName
              ''#!${fish}

              # For packages that need one of their XDG Base directories to be mutable
              set -g mutable_bin (${mktemp} --directory)
              set -g state_dir (${mktemp} --directory)
              set -g config_dir (${mktemp} --directory)
              set -g data_dir (${mktemp} --directory)
              set -g runtime_dir (${mktemp} --directory)
              set -g cache_dir (${mktemp} --directory)

              # Make mutable copies of the contents of any XDG Base Directory in the Home Manager configuration.
              # This is because some programs need to be able to write to one of these directories e.g. `fish`.
              ${copy} --no-preserve=mode --recursive --dereference ${activationPackage}/home-files/.config/* ''$config_dir
              ${copy} --no-preserve=mode --recursive --dereference ${activationPackage}/home-files/.local/share/* ''$data_dir

              for program in ${activationPackage}/home-path/bin/*
                set base (${basename} ''$program)

                switch "$base"
                  case env
                    # TODO: Wrapping this caused an infinite loop so I'll copy it instead
                    ${copy} -L ''$program ''$mutable_bin/env
                  case fish
                    echo -s >''$mutable_bin/''$base "#!${fish}
                      # I unexport the XDG Base directories so host programs pick up the host's XDG directories.
                      XDG_CONFIG_HOME=''$config_dir XDG_DATA_HOME=''$data_dir XDG_STATE_HOME=''$state_dir XDG_RUNTIME_DIR=''$runtime_dir XDG_CACHE_HOME=''$cache_dir \
                      ''$program \
                        --init-command 'set --unexport XDG_CONFIG_HOME' \
                        --init-command 'set --unexport XDG_DATA_HOME' \
                        --init-command 'set --unexport XDG_STATE_HOME' \
                        --init-command 'set --unexport XDG_RUNTIME_DIR' \
                        --init-command 'set --unexport XDG_CACHE_HOME_DIR' \
                        " ' ''$argv'
                  case '*'
                    echo -s >''$mutable_bin/''$base "#!${fish}
                      XDG_CONFIG_HOME=''$config_dir XDG_DATA_HOME=''$data_dir XDG_STATE_HOME=''$state_dir XDG_RUNTIME_DIR=''$runtime_dir XDG_CACHE_HOME=''$cache_dir \
                      ''$program" ' ''$argv'
                end

                ${chmod} +x ''$mutable_bin/''$base
              end

              # My login shell .profile sets the LOCALE_ARCHIVE for me, but it sets it to
              # ~/.nix-profile/lib/locale/locale-archive and I won't have that in a 'sealed' environment so instead
              # I will source the Home Manager setup script because it sets the LOCALE_ARCHIVE to the path of the
              # archive in the Nix store.
              set --prepend fish_function_path ${foreignEnvFunctionPath}
              PATH="${coreutilsBinaryPath}:''$PATH" fenv source ${activationPackage}/home-path/etc/profile.d/hm-session-vars.sh >/dev/null
              set -e fish_function_path[1]

              fish_add_path --global --prepend ${activationPackage}/home-files/.local/bin
              fish_add_path --global --prepend ''$mutable_bin

              # Set fish as the default shell
              set --global --export SHELL (${which} fish)

              # Compile my custom themes for bat.
              chronic bat cache --build

              exec ''$SHELL ''$argv
              '';
          in
            {
              apps.default = {
                type = "app";
                program = "${shellBootstrap}/bin/${shellBootstrapScriptName}";
                programDerivation = shellBootstrap;
              };
            }
        );
      # The default output contains symbolic links to all the packages whose dependencies I want cache through CI.
      # This way in my CI pipeline I can build this output and populate my binary cache with every dependency that gets
      # pulled in. There are some open issues for providing an easier way to build all packages for CI.
      # issue: https://github.com/NixOS/nix/issues/7165
      # issue: https://github.com/NixOS/nix/issues/7157
      defaultOutputs = flake-utils.lib.eachSystem
        (with flake-utils.lib.system; [ x86_64-linux x86_64-darwin ])
        (system:
          let
            pkgs = import nixpkgs {inherit system;};
            inherit (pkgs.lib.attrsets) optionalAttrs mapAttrs;
            hasSystem = builtins.hasAttr system;

            homeConfigurationOutputsBySystem = homeManagerOutputs.legacyPackages;
            homeConfigurationDerivationsByName = optionalAttrs
              (hasSystem homeConfigurationOutputsBySystem)
              (mapAttrs (key: value: value.activationPackage) homeConfigurationOutputsBySystem.${system}.homeConfigurations);

            shellOutputsBySystem = shellOutputs.apps;
            shellDerivationByName = optionalAttrs
              (hasSystem shellOutputsBySystem)
              {shell = shellOutputsBySystem.${system}.default.programDerivation;};

            allDerivationsByName = homeConfigurationDerivationsByName // shellDerivationByName;
          in
            { packages.default = pkgs.linkFarm "packages-to-cache" allDerivationsByName; }
        );
      bundlerOutputs = flake-utils.lib.eachSystem
        (with flake-utils.lib.system; [ x86_64-linux ])
        (system:
          { bundlers = nix-appimage.bundlers.${system}; }
        );
    in
      recursiveMerge [homeManagerOutputs defaultOutputs shellOutputs bundlerOutputs];
}
