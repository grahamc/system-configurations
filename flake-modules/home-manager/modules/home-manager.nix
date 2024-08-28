{
  config,
  lib,
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) hostName username homeDirectory isHomeManagerRunningAsASubmodule;
  inherit (lib.attrsets) optionalAttrs;
  inherit (pkgs.stdenv) isLinux;

  # Scripts for switching generations and upgrading flake inputs.
  hostctl-switch = pkgs.writeShellApplication {
    name = "hostctl-switch";
    runtimeInputs = with pkgs; [nix-output-monitor];
    text = ''
      cd "${config.repository.directory}"
      ${config.home.profileDirectory}/bin/home-manager switch --flake "${config.repository.directory}#${hostName}" "''$@" |& nom
    '';
  };

  hostctl-preview-switch = pkgs.writeShellApplication {
    name = "hostctl-preview-switch";
    runtimeInputs = with pkgs; [coreutils gnugrep nix];
    text = ''
      cd "${config.repository.directory}"

      oldGenerationPath="$(${config.home.profileDirectory}/bin/home-manager generations | head -1 | grep -E --only-matching '/nix.*$')"

      newGenerationPath="$(nix build --no-link --print-out-paths .#homeConfigurations.${hostName}.activationPackage)"

      cyan='\033[1;0m'
      printf "%bPrinting switch preview...\n" "$cyan"
      nix store diff-closures "''$oldGenerationPath" "''$newGenerationPath"
    '';
  };

  hostctl-upgrade = pkgs.writeShellApplication {
    name = "hostctl-upgrade";
    runtimeInputs = with pkgs; [coreutils gitMinimal less direnv nix];
    text = ''
      cd "${config.repository.directory}"

      rm -f ~/.local/state/nvim/*.log
      rm -f ~/.local/state/nvim/undo/*

      git fetch
      if [ -n "$(git log 'HEAD..@{u}' --oneline)" ]; then
          echo "$(echo 'Commits made since last pull:'$'\n'; git log '..@{u}')" | less

          if [ -n "$(git status --porcelain)" ]; then
              git stash --include-untracked --message 'Stashed for upgrade'
          fi

          direnv allow
          direnv exec "$PWD" nix-direnv-reload
          direnv exec "$PWD" git pull
      else
          # Something probably went wrong so we're trying to upgrade again even
          # though there's nothing to pull. In which case, just run the hook as
          # though we did.
          direnv allow
          direnv exec "$PWD" nix-direnv-reload
          direnv exec "$PWD" lefthook run post-rewrite
      fi
    '';
  };

  update-check =
    pkgs.writeShellApplication
    {
      name = "update-check";
      runtimeInputs = with pkgs; [coreutils gitMinimal libnotify wezterm];
      text = ''
        log="$(mktemp --tmpdir 'nix_XXXXX')"
        exec 2>"$log" 1>"$log"
        trap 'notify-send -title "Home Manager" -message "Update check failed :( Check the logs in $log"' ERR

        cd "${config.repository.directory}"

        git fetch
        if [ -n "$(git log 'HEAD..@{u}' --oneline)" ]; then
          notify-send -title "Home Manager" -message "Updates available, click here to update." -execute 'wezterm --config "default_prog={[[${hostctl-upgrade}/bin/hostctl-upgrade]]}" --config "exit_behavior=[[Hold]]"'
        fi
      '';
    };
in
  lib.mkMerge [
    {
      # The `man` in nixpkgs is only intended to be used for NixOS, it doesn't work properly on
      # other OS's so I'm disabling it.
      #
      # home-manager issue: https://github.com/nix-community/home-manager/issues/432
      programs.man.enable = false;

      home = {
        # Since I'm not using the nixpkgs man, I have any packages I install their man outputs so my
        # system's `man` can find them.
        extraOutputsToInstall = ["man"];

        # This value determines the Home Manager release that your
        # configuration is compatible with. This helps avoid breakage
        # when a new Home Manager release introduces backwards
        # incompatible changes.
        #
        # You can update Home Manager without changing this value. See
        # the Home Manager release notes for a list of state version
        # changes in each release.
        stateVersion = "23.11";
      };
    }

    # These are all things that don't need to be done when home manager is being run as a submodule inside of
    # another host manager, like nix-darwin. They don't need to be done because the outer host manager will do them.
    (optionalAttrs (!isHomeManagerRunningAsASubmodule) {
      home = {
        # Home Manager needs a bit of information about you and the
        # paths it should manage.
        inherit username homeDirectory;

        packages = [
          hostctl-preview-switch
          hostctl-switch
          hostctl-upgrade
        ];

        # Show me what changed everytime I switch generations e.g. version updates or added/removed files.
        activation = {
          printGenerationDiff = lib.hm.dag.entryAnywhere ''
            # On the first activation, there won't be an old generation.
            if [ -n "''${oldGenPath+set}" ] ; then
              nix store diff-closures $oldGenPath $newGenPath
            fi
          '';
        };
      };

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      # Don't notify me of news updates when I switch generation. Ideally, I'd disable news altogether since I don't
      # read it:
      # issue: https://github.com/nix-community/home-manager/issues/2033#issuecomment-1698406098
      news.display = "silent";

      systemd = optionalAttrs isLinux {
        user = {
          services = {
            home-manager-delete-old-generations = {
              Unit = {
                Description = "Delete old generations of home-manager";
              };
              Service = {
                Type = "oneshot";
                ExecStart = "${config.home.profileDirectory}/bin/home-manager expire-generations '-180 days'";
              };
            };
            home-manager-update-check = {
              Unit = {
                Description = "Check for home-manager updates";
              };
              Service = {
                Type = "oneshot";
                ExecStart = "${update-check}/bin/update-check";
              };
            };
          };

          timers = {
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
            home-manager-update-check = {
              Unit = {
                Description = "Check for home-manager updates";
              };
              Timer = {
                OnCalendar = "daily";
                Persistent = true;
              };
              Install = {
                WantedBy = ["timers.target"];
              };
            };
          };
        };
      };
    })
  ]
