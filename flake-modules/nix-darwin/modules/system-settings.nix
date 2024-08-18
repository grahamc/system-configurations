{pkgs, ...}: {
  # extend sudo timeout to 30 minutes from the default 5 because sometimes it
  # times out in the middle of a rebuild.
  security.sudo.extraConfig = ''
    Defaults        timestamp_timeout=30
  '';

  system = {
    # TODO: This option is marked internal
    nvram.variables."AutoBoot" = "%00";

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

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

    # Apply setting immediately so I don't have to logout/reboot.
    # source: https://medium.com/@zmre/nix-darwin-quick-tip-activate-your-preferences-f69942a93236
    # TODO: https://github.com/LnL7/nix-darwin/issues/658
    activationScripts.postUserActivation.text = ''
      # Following line should allow us to avoid a logout/login cycle
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

    # Copied from the nix-darwin option 'security.pam.enableSudoTouchIdAuth'
    # with the addition of pam-reattach so it works with tmux.
    #
    # TODO: I can remove this if this PR gets merged
    # https://github.com/LnL7/nix-darwin/issues/985
    activationScripts.postActivation.text = let
      mkSudoTouchIdAuthScript = isEnabled: let
        file = "/etc/pam.d/sudo";
        option = "security.pam.enableSudoTouchIdAuth";
        sed = "${pkgs.gnused}/bin/sed";
      in ''
        ${
          if isEnabled
          then ''
            # Enable sudo Touch ID authentication, if not already enabled
            if ! grep 'pam_tid.so' ${file} > /dev/null; then
              ${sed} -i '2i\
            auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so ignore_ssh # nix-darwin: ${option}\
            auth       sufficient     pam_tid.so # nix-darwin: ${option}
              ' ${file}
            fi
          ''
          else ''
            # Disable sudo Touch ID authentication, if added by nix-darwin
            if grep '${option}' ${file} > /dev/null; then
              ${sed} -i '/${option}/d' ${file}
            fi
          ''
        }
      '';
    in ''
      # PAM settings
      echo >&2 "[bigolu] setting up pam..."
      ${mkSudoTouchIdAuthScript true}
    '';
  };
}
