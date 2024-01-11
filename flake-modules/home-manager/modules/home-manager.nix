{
  config,
  lib,
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) hostName username homeDirectory isHomeManagerRunningAsASubmodule;
  inherit (specialArgs.flakeInputs) self;
  inherit (lib.attrsets) optionalAttrs;
  inherit (pkgs.stdenv) isLinux;

  # Scripts for switching generations and upgrading flake inputs.
  hostctl-switch = pkgs.writeShellApplication {
    name = "hostctl-switch";
    text = ''
      cd "${config.repository.directory}"
      home-manager switch --flake "${config.repository.directory}#${hostName}" "''$@" |& nom
    '';
  };

  hostctl-preview-switch = pkgs.writeShellApplication {
    name = "hostctl-preview-switch";
    text = ''
      cd "${config.repository.directory}"

      oldGenerationPath="$(home-manager generations | head -1 | grep -E --only-matching '/nix.*$')"

      newGenerationPath="$(nix build --no-link --print-out-paths .#homeConfigurations.${hostName}.activationPackage)"

      cyan='\033[1;0m'
      printf "%bPrinting switch preview...\n" "$cyan"
      nix store diff-closures "''$oldGenerationPath" "''$newGenerationPath"
    '';
  };

  hostctl-upgrade =
    pkgs.writeShellApplication
    {
      name = "hostctl-upgrade";
      text = ''
        cd "${config.repository.directory}"
        home-manager switch --flake "${config.repository.directory}#${hostName}" ${self.lib.updateFlags.home} "''$@" |& nom
        nix-upgrade-profiles
      '';
    };

  hostctl-preview-upgrade = pkgs.writeShellApplication {
    name = "hostctl-preview-upgrade";
    text = ''
      cd "${config.repository.directory}"

      oldGenerationPath="$(home-manager generations | head -1 | grep -E --only-matching '/nix.*$')"

      newGenerationPath="$(nix build --no-write-lock-file ${self.lib.updateFlags.home} --no-link --print-out-paths .#homeConfigurations.${hostName}.activationPackage)"

      cyan='\033[1;0m'
      printf "%bPrinting upgrade preview...\n" "$cyan"
      nix store diff-closures "''$oldGenerationPath" "''$newGenerationPath"
    '';
  };
in
  lib.mkMerge [
    {
      # The `man` in nixpkgs is only intended to be used for NixOS, it doesn't work properly on other OS's so I'm disabling
      # it. Since I'm not using the nixpkgs man, I have any packages I install their man outputs so my
      # system's `man` can find them.
      #
      # home-manager issue: https://github.com/nix-community/home-manager/issues/432
      programs.man.enable = false;
      home.extraOutputsToInstall = ["man"];

      # This value determines the Home Manager release that your
      # configuration is compatible with. This helps avoid breakage
      # when a new Home Manager release introduces backwards
      # incompatible changes.
      #
      # You can update Home Manager without changing this value. See
      # the Home Manager release notes for a list of state version
      # changes in each release.
      home.stateVersion = "23.11";

      repository.git.onChange = [
        {
          # This should be the first check since other checks might depend on new files
          # being linked, or removed files being unlinked, in order to work. For example, if a new
          # bat theme is added, the theme needs to be linked before we can rebuild the bat cache.
          priority = 100;
          patterns = {
            added = [".*"];
            deleted = [".*"];
            modified = [''^flake-modules/'' ''^flake\.nix$'' ''^flake\.lock$''];
          };
          action = ''
            just switch
          '';
        }
        {
          patterns = {
            modified = [''^\.lefthook.yml$''];
          };
          action = ''
            just install-git-hooks
          '';
        }
      ];
    }
    # These are all things that don't need to be done when home manager is being run as a submodule inside of
    # another host manager, like nix-darwin. They don't need to be done because the outer host manager will do them.
    (optionalAttrs (!isHomeManagerRunningAsASubmodule) {
      # Home Manager needs a bit of information about you and the
      # paths it should manage.
      home.username = username;
      home.homeDirectory = homeDirectory;

      home.packages = [
        hostctl-switch
        hostctl-upgrade
        hostctl-preview-switch
        hostctl-preview-upgrade
      ];

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      # Don't notify me of news updates when I switch generation. Ideally, I'd disable news altogether since I don't
      # read it:
      # issue: https://github.com/nix-community/home-manager/issues/2033#issuecomment-1698406098
      news.display = "silent";

      # Show me what changed everytime I switch generations e.g. version updates or added/removed files.
      home.activation = {
        printGenerationDiff = lib.hm.dag.entryAnywhere ''
          # On the first activation, there won't be an old generation.
          if [ -n "''${oldGenPath+set}" ] ; then
            nix store diff-closures $oldGenPath $newGenPath
          fi
        '';
      };

      systemd = optionalAttrs isLinux {
        user.services = {
          home-manager-delete-old-generations = {
            Unit = {
              Description = "Delete old generations of home-manager";
            };
            Service = {
              Type = "oneshot";
              ExecStart = "${config.home.profileDirectory}/bin/home-manager expire-generations '-180 days'";
            };
          };
        };

        user.timers = {
          home-manager-delete-old-generations = {
            Unit = {
              Description = "Delete old generations of home-manager";
            };
            Timer = {
              OnCalendar = "monthly";
              Persistent = true;
            };
            Install = {
              WantedBy = ["timers.target"];
            };
          };
        };
      };
    })
  ]
