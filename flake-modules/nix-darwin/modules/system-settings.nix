_: {
  security = {
    # extend sudo timeout to 30 minutes from the default 5 because sometimes it
    # times out in the middle of a rebuild.
    sudo.extraConfig = ''
      Defaults        timestamp_timeout=30
    '';
    pam.enableSudoTouchIdAuth = true;
  };

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

    activationScripts.postUserActivation.text = ''
      # Apply settings immediately so I don't have to logout/reboot.
      # source: https://medium.com/@zmre/nix-darwin-quick-tip-activate-your-preferences-f69942a93236
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

      # TODO: Some settings may not apply without doing this:
      # https://github.com/LnL7/nix-darwin/issues/658#issuecomment-1557604877
      killall Dock
    '';
  };
}
