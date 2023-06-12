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
        gc = {
          automatic = true;
          options = "--delete-old";
        };
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
          trackpad.Clicking = true;
        };
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
