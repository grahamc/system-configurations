{pkgs, ...}: {
  system = {
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

    # Copied from the nix-darwin option 'security.pam.enableSudoTouchIdAuth' with the addition of pam-reattach so it works with tmux.
    #
    # TODO: I should upstream this
    activationScripts.myPam.text = let
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
      echo >&2 "setting up pam..."
      ${mkSudoTouchIdAuthScript true}
    '';
  };
}
