{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlink
      ;
    inherit (specialArgs) isGui;
    inherit (lib.attrsets) optionalAttrs;
  in
    {
      home.packages = with pkgs; [
        fbterm
      ];

      home.file = {
        ".fbtermrc".source = makeOutOfStoreSymlink "linux-desktop/fbterm/fbtermrc";
      } // optionalAttrs isGui {
        ".local/bin/night-theme-switcher-fix".source = makeOutOfStoreSymlink "linux-desktop/gnome/night-theme-switcher-fix.sh";
      };

      xdg.configFile = optionalAttrs isGui {
        "autostart/theme-sync.desktop".source = makeOutOfStoreSymlink "linux-desktop/gnome/theme-sync.desktop";
        "fontconfig/fonts.conf".source = makeOutOfStoreSymlink "linux-desktop/fontconfig/local.conf";
        "fontconfig/conf.d/10-nerd-font-symbols.conf".source = makeOutOfStoreSymlink "linux-desktop/fontconfig/10-nerd-font-symbols.conf";
      };
    }
