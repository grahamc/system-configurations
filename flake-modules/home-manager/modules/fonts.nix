{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (specialArgs) isGui;
    inherit (pkgs.stdenv) isLinux;
  in lib.mkIf (isLinux && isGui) {
    repository.symlink.xdg.configFile = {
      "fontconfig/fonts.conf".source = "fontconfig/local.conf";
      # TODO: I should pull this file from the Nerdfont repository so it stays up to date, but nix can't do sparse
      # checkouts and I don't want to download a ~3gb repo just for one file.
      # issue: https://github.com/NixOS/nix/issues/5811
      "fontconfig/conf.d/10-nerd-font-symbols.conf".source = "fontconfig/10-nerd-font-symbols.conf";
    };
    fonts.fontconfig.enable = true;
    home.packages = with pkgs; [
      (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
      iosevka
      inter
    ];

    # Wezterm can't read my fonts from Nix despite the showing up in fontconfig so I copy all the Nix fonts to
    # $XDG_DATA_HOME/fonts. Wezterm also can't read the font when it is a symlink to the Nix store so I
    # dereference the symbolic links. I don't preserve the mode of the original files since they are read
    # only and I want to be able to remove everything in the directory before copying again.
    home.activation.fontSetup = lib.hm.dag.entryAfter
      # Must be after `installPackages` since that's when the fonts get installed.
      ["installPackages"]
      ''
        target_directory='${config.xdg.dataHome}/fonts'
        rm -rf "''$target_directory/*"
        cp --no-preserve=mode --recursive --dereference '${config.home.profileDirectory}/share/fonts/.' "''$target_directory"
      '';
  }

