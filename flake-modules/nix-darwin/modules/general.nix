{ config, specialArgs, pkgs, ... }:
  let
    inherit (specialArgs) hostName homeDirectory username repositoryDirectory;
    inherit (specialArgs.flakeInputs) self;

    # Scripts for switching generations and upgrading flake inputs.
    packages = [
      (pkgs.writeShellApplication {
        name = "hostctl-switch";
        runtimeInputs = with pkgs; [coreutils-full];
        text = ''
          # Get sudo authentication now so I don't have to wait for it to ask me later
          sudo --validate

          oldGenerationPath="''$(readlink --canonicalize ${config.system.profile})"

          darwin-rebuild switch --flake "${repositoryDirectory}#${hostName}" "''$@"

          newGenerationPath="''$(readlink --canonicalize ${config.system.profile})"

          cyan='\033[1;0m'
          printf "%bPrinting generation diff...\n" "$cyan"
          nix store diff-closures "''$oldGenerationPath" "''$newGenerationPath"
        '';
      })
      (pkgs.writeShellApplication {
        name = "hostctl-upgrade";
        runtimeInputs = with pkgs; [coreutils-full];
        text = ''
          # Get sudo authentication now so I don't have to wait for it to ask me later
          sudo --validate

          oldGenerationPath="''$(readlink --canonicalize ${config.system.profile})"

          darwin-rebuild switch --flake "${repositoryDirectory}#${hostName}" ${self.lib.updateFlags.darwin} "''$@"

          brew update
          brew upgrade --greedy
          brew autoremove
          brew cleanup

          newGenerationPath="''$(readlink --canonicalize ${config.system.profile})"

          cyan='\033[1;0m'
          printf "%bPrinting generation diff...\n" "$cyan"
          nix store diff-closures "''$oldGenerationPath" "''$newGenerationPath"
        '';
      })
    ];
  in
    {
      nix = {
        useDaemon = true;
        settings = {
          trusted-users = [
            "root"
            username
          ];
          experimental-features = [
            "nix-command"
            "flakes"
            "auto-allocate-uids"
          ];
          auto-allocate-uids = true;
        };
      };

      launchd.daemons.nix-gc = {
        command = ''
          /bin/sh -c ' \
            export PATH="${config.nix.package}/bin:''$PATH"; \
            nix-env --profile /nix/var/nix/profiles/system --delete-generations old; \
            nix-env --profile /nix/var/nix/profiles/default --delete-generations old; \
            nix-env --profile /nix/var/nix/profiles/per-user/root/profile --delete-generations old; \
            nix-env --profile /nix/var/nix/profiles/per-user/root/channels --delete-generations old; \
            nix-env --profile ${homeDirectory}/.local/state/nix/profiles/home-manager --delete-generations old; \
            nix-env --profile ${homeDirectory}/.local/state/nix/profiles/profile --delete-generations old; \
            nix-env --profile ${homeDirectory}/.local/state/nix/profiles/channels --delete-generations old; \
            nix-collect-garbage --delete-old; \
          '
        '';
        environment.NIX_REMOTE = "daemon";
        serviceConfig.RunAtLoad = false;
        serviceConfig.StartCalendarInterval = [ {Hour = 3; Minute = 15;} ];
      };

      users.users.${username} = {
        home = homeDirectory;
      };

      security.pam.enableSudoTouchIdAuth = true;

      homebrew = {
        enable = true;
        onActivation.cleanup = "zap";
        casks = [
          "wezterm"
          "xcodes"
          "hammerspoon"
          "visual-studio-code"
          "gitkraken"
          "firefox-developer-edition"
          "finicky"
          "docker"
          "unnaturalscrollwheels"
          "MonitorControl"
          "responsively"
          "element"
          "nightfall"
        ];
        caskArgs = {
          # Don't quarantine the casks so macOS doesn't warn me before opening any of them.
          no_quarantine = true;
        };
        taps = [
          "homebrew/cask-versions"
        ];
      };

      system = {
        keyboard = {
          enableKeyMapping = true;
          remapCapsLockToControl = true;
        };
        activationScripts.postActivation.text = ''
          # When hibernating, actually power down instead of the default behaviour where a hibernation file is
          # created, but the computer stays in suspension.
          sudo pmset -b hibernatemode 25

          # Homebrew services won't have any of my nix profile /bin directories on their path so below I'm copying
          # the programs they need into a directory that is on their $PATH.
          #
          # One of hammerspoon's plugins, stackline, needs yabai.
          test -e /usr/local/bin/yabai && rm /usr/local/bin/yabai
          cp ${config.services.yabai.package}/bin/yabai /usr/local/bin/

          # Disable the Gatekeeper so I can open apps that weren't codesigned without being warned.
          sudo spctl --master-disable
        '';
        defaults = {
          NSGlobalDomain = {
            ApplePressAndHoldEnabled = false;
            NSAutomaticQuoteSubstitutionEnabled = false;
          };
          dock = {
            autohide = true;
            mru-spaces = false;
          };
          trackpad = {
            Clicking = true;
            Dragging = true;
          };
          LaunchServices = {
            LSQuarantine = false;
          };
        };
        # With Nix's new `auto-allocate-uids` feature, build users get created on demand. This means this check
        # will always fail since the build users won't be present until the build actually starts so I'm disabling
        # the check.
        checks.verifyBuildUsers = false;
      };

      environment = {
        systemPackages = packages;
        profiles = [
          # TODO: Adding my user profile here so that it's `/bin` directory gets added to the $PATH of
          # `launchd.user.agents`. nix-darwin attempts to do this, but it uses '$HOME/.nix-profile' and '$HOME' never
          # gets expanded.
          # issue: https://github.com/LnL7/nix-darwin/issues/406
          "${homeDirectory}/.nix-profile"
          # skhd needs my yabai-* scripts
          "${homeDirectory}/.local"
        ];
      };

      services = {
        yabai = {
          enable = true;
          enableScriptingAddition = true;
        };
        skhd = {
          enable = true;
          # skhd needs itself on the $PATH for any of the shortcuts in my skhdrc that use the skhd command to send keys.
          package = pkgs.writeShellApplication {
            name = "skhd";
            runtimeInputs = with pkgs; [skhd];
            text = ''
              exec skhd "''$@"
            '';
          };
        };
      };

      programs.bash.enable = false;
    }
