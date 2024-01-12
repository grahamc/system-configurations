_: {
  services = {
    yabai = {
      enable = true;
      enableScriptingAddition = true;
    };
  };

  # This file gets set in the nix-darwin yabai module to allow users to manually install the
  # scripting addition. In doing so it gets the hash of the yabai executable which is Import
  # from Derivation (IFD). Since I don't need to run the scripting addition command manually
  # I'm disabling it.
  environment.etc."sudoers.d/yabai".enable = false;
}
