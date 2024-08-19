{config, ...}: {
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";

    casks = [
      "wezterm@nightly"
      "xcodes"
      "hammerspoon"
      "visual-studio-code"
      "gitkraken"
      "firefox@developer-edition"
      "google-chrome"
      "finicky"
      "docker"
      "unnaturalscrollwheels"
      "MonitorControl"
      "responsively"
      "element"
      "nightfall"
    ];

    caskArgs = {
      # Don't quarantine the casks so macOS doesn't warn me before opening any
      # of them.
      no_quarantine = true;
    };

    taps = [
      "homebrew/cask-versions"
    ];
  };

  # TODO:
  # https://github.com/LnL7/nix-darwin/issues/663
  system.activationScripts.postActivation.text = ''
    # Homebrew services won't have any of my nix profile /bin directories on
    # their path so below I'm copying the programs they need into a directory
    # that is on their $PATH.
    #
    # One of hammerspoon's plugins, stackline, needs yabai.
    test -e /usr/local/bin/yabai && rm /usr/local/bin/yabai
    cp ${config.services.yabai.package}/bin/yabai /usr/local/bin/

    # Disable the Gatekeeper so I can open apps that weren't codesigned without
    # being warned.
    sudo spctl --master-disable
  '';
}
