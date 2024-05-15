{
  lib,
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) isGui flakeInputs;
  inherit (pkgs.stdenv) isLinux isDarwin;
  linux =
    lib.mkIf
    (isGui && isLinux)
    {
      home.activation.gnomeXkbSetup =
        lib.hm.dag.entryAfter
        ["writeBoundary"]
        ''
          # Use capslock as ctrl
          ${pkgs.glib}/bin/gsettings set org.gnome.desktop.input-sources xkb-options "['ctrl:nocaps']"
          # This was bound to alt+`, but I use that for vscode so I'm clearing it.
          ${pkgs.glib}/bin/gsettings set org.gnome.desktop.wm.keybindings switch-group '[]'
        '';
    };

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
in
  lib.mkMerge [linux mac]
