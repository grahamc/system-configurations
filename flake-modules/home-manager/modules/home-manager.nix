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
      # TODO: So `just` has access to `hostctl-switch`, not a great solution
      PATH="${config.home.profileDirectory}/bin:$PATH"
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
      runtimeInputs = with pkgs; [coreutils gitMinimal libnotify];
      text = ''
        log="$(mktemp --tmpdir 'home_manager_update_XXXXX')"
        exec 2>"$log" 1>"$log"
        trap 'notify-send --app-name "Home Manager" "Update check failed :( Check the logs in $log"' ERR

        cd "${config.repository.directory}"

        git fetch
        if [ -z "$(git log 'HEAD..@{u}' --oneline)" ]; then
          # TODO: I want to use action buttons on the notification, but it isn't
          # working.
          #
          # TODO: With `--wait`, `notify-send` only exits if the x button is
          # clicked. I assume that I want to upgrade if I click the x button
          # within one hour. Using `timeout` I can kill `notify-send` once one
          # hour passes.  This behavior isn't correct based on the `notify-send`
          # manpage, not sure if the bug is with `notify-send` or my desktop
          # environment, COSMIC.
          timeout 1h \
            notify-send \
              --wait \
              --app-name 'Home Manager' \
              'Updates are available. To update, click the "x" button now or after the notification has been dismissed.'
          if [ $? -ne 124 ]; then
            flatpak run org.wezfurlong.wezterm --config 'default_prog={[[${hostctl-upgrade}/bin/hostctl-upgrade]]}' --config 'exit_behavior=[[Hold]]'
          fi
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
