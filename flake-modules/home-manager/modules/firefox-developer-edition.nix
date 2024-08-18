{
  lib,
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) isGui;
  inherit (pkgs.stdenv) isLinux isDarwin;
  linux =
    lib.mkIf
    (isGui && isLinux)
    {
      repository.symlink.xdg.dataFile = {
        "applications/my-firefox.desktop".source = "firefox-developer-edition/my-firefox.desktop";
      };

      repository.symlink.xdg.executable."my-firefox".source = "firefox-developer-edition/my-firefox";
    };
  darwin =
    lib.mkIf
    (isGui && isDarwin)
    {
      repository.symlink.home.file.".finicky.js".source = "firefox-developer-edition/finicky/finicky.js";
    };
in
  lib.mkMerge [linux darwin]
