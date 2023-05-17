{ config, lib, specialArgs, pkgs, ... }:
  let
    inherit (specialArgs) hostName homeDirectory username repositoryDirectory;
    inherit (specialArgs.flakeInputs) self;

    # Scripts for switching generations and upgrading flake inputs.
    packages = [
      (pkgs.writeShellApplication {
        name = "hostctl-switch";
        runtimeInputs = with pkgs; [nvd];
        text = ''
          oldGenerationPath="''$(readlink --canonicalize ${config.system.profile})"

          darwin-rebuild switch --flake "${repositoryDirectory}#${hostName}" "''$@"

          newGenerationPath="''$(readlink --canonicalize ${config.system.profile})"
          nvd diff "''$oldGenerationPath" "''$newGenerationPath"
        '';
      })
      (pkgs.writeShellApplication {
        name = "hostctl-upgrade";
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
        gc.automatic = true;
      };

      users.users.${username} = {
        home = homeDirectory;
        inherit packages;
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
          rm /usr/local/bin/skhd
          cp ${pkgs.skhd}/bin/skhd /usr/local/bin/
          # One of hammerspoon's plugins, stackline, needs yabai.
          rm /usr/local/bin/yabai
          cp ${config.services.yabai.package}/bin/yabai /usr/local/bin/
        '';
        defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;
      };

      environment.etc = {
        "sudoers.d/10-my-commands".text = ''
          # This allows yabai to inject code in Dock.app so it can properly function. Also lets me reload my config
          # without a password
          ALL ALL=NOPASSWD: /usr/local/bin/yabai
        '';
      };

      services = {
        yabai.enable = true;
        skhd.enable = true;
      };

      programs.bash.enable = false;
    }
