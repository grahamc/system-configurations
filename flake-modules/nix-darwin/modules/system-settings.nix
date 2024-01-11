{...}: {
  security.pam.enableSudoTouchIdAuth = true;

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
  };
}
