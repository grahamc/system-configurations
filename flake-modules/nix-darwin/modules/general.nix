{ config, lib, specialArgs, pkgs, ... }:
  let
    inherit (specialArgs) hostName homeDirectory username repositoryDirectory;
    inherit (specialArgs.flakeInputs) self;

    # Scripts for switching generations and upgrading flake inputs.
    packages = [
      (pkgs.writeShellApplication {
        name = "hostctl-switch";
        runtimeInputs = with pkgs; [nvd coreutils-full];
        text = ''
          oldGenerationPath="''$(readlink --canonicalize ${config.system.profile})"

          darwin-rebuild switch --flake "${repositoryDirectory}#${hostName}" "''$@"

          newGenerationPath="''$(readlink --canonicalize ${config.system.profile})"
          nvd diff "''$oldGenerationPath" "''$newGenerationPath"
        '';
      })
      (pkgs.writeShellApplication {
        name = "hostctl-upgrade";
        runtimeInputs = with pkgs; [nvd coreutils-full];
        text = ''
          oldGenerationPath="''$(readlink --canonicalize ${config.system.profile})"

          darwin-rebuild switch --flake "${repositoryDirectory}#${hostName}" ${self.lib.updateFlags.darwin} "''$@"

          brew update
          brew upgrade
          brew autoremove
          brew cleanup

          newGenerationPath="''$(readlink --canonicalize ${config.system.profile})"
          nvd diff "''$oldGenerationPath" "''$newGenerationPath"
        '';
      })
    ];
  in
    {
      nix = {
        useDaemon = true;
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

      fonts = {
        fontDir.enable = true;
        fonts = with pkgs; [
          (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
          jetbrains-mono
        ];
      };

      security.pam.enableSudoTouchIdAuth = true;

      homebrew = {
        enable = true;
        casks = [
          "spaceid"
          "wezterm"
          "xcodes"
          "hammerspoon"
          "visual-studio-code"
          "gitkraken"
          "firefox-developer-edition"
          "finicky"
          "docker"
        ];
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
          # The services in `config.services.*` get launched before I login so the directory that nix-darwin installs
          # packages to won't be on their $PATH. So here I'm making copying the programs needed by these services
          # into a directory that's on the $PATH by default:
          #
          # skhd needs itself on the $PATH for any of the shortcuts in my skhdrc that use the skhd command to send keys.
          test -e /usr/local/bin/skhd && rm /usr/local/bin/skhd
          cp ${pkgs.skhd}/bin/skhd /usr/local/bin/
          # One of hammerspoon's plugins, stackline, needs yabai.
          test -e /usr/local/bin/yabai && rm /usr/local/bin/yabai
          cp ${config.services.yabai.package}/bin/yabai /usr/local/bin/
        '';
        defaults = {
          NSGlobalDomain = {
            ApplePressAndHoldEnabled = false;
            NSAutomaticQuoteSubstitutionEnabled = false;
          };
          dock.autohide = true;
          trackpad = {
            Clicking = true;
            Dragging = true;
          };
        };
        # With Nix's new `auto-allocate-uids` feature, build users get created on demand. This means this check
        # will always fail since the build users won't be present until the build actually starts so I'm disabling
        # the check.
        checks.verifyBuildUsers = false;
      };

      environment = {
        etc = {
          "sudoers.d/10-my-commands".text = ''
            # This allows yabai to inject code in Dock.app so it can properly function. Also lets me reload my config
            # without a password
            ALL ALL=NOPASSWD: /usr/local/bin/yabai
          '';
        };
        systemPackages = packages;
      };

      services = {
        yabai.enable = true;
        skhd.enable = true;
      };

      programs.bash.enable = false;
    }
