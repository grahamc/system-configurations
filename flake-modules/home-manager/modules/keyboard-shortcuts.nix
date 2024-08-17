{
  lib,
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) isGui flakeInputs;
  inherit (pkgs.stdenv) isDarwin isLinux;

  stacklineWithoutConfig = pkgs.stdenv.mkDerivation {
    pname = "mystackline";
    version = "0.1";
    src = flakeInputs.stackline;
    installPhase = ''
      mkdir -p $out
      cp -r $src/* $out/
      # remove the config that stackline comes with so I can link mine later
      rm $out/conf.lua
    '';
  };

  mac =
    lib.mkIf
    (isGui && isDarwin)
    {
      repository.symlink = {
        xdg = {
          configFile = {
            "yabai/yabairc".source = "yabai/yabairc";
            "skhd/skhdrc".source = "skhd/skhdrc";
          };
        };

        home.file = {
          ".hammerspoon/init.lua".source = "hammerspoon/init.lua";
          ".hammerspoon/stackline/conf.lua".source = "hammerspoon/stackline/conf.lua";
          "Library/Keyboard Layouts/NoAccentKeys.bundle".source = "keyboard/US keyboard - no accent keys.bundle";
        };
      };

      home.file = {
        ".hammerspoon/stackline" = {
          source = stacklineWithoutConfig;
          # I'm recursively linking because I link into this directory in other
          # places.
          recursive = true;
        };
      };

      targets.darwin.keybindings = {
        # By default, a bell sound goes off whenever I use ctrl+/, this disables that.
        "^/" = "noop:";
      };
    };

  linux =
    lib.mkIf
    (isGui && isLinux)
    {
      repository.symlink = {
        xdg = {
          configFile = {
            # TODO: When COSMIC writes to this file it replaces the symlink with a regular copy :(
            "cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom".source = "cosmic/v1-shortcuts";
          };
        };
      };
    };
in
  lib.mkMerge [mac linux]
