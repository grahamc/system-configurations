{
  lib,
  pkgs,
  ...
}: {
  repository.symlink.xdg.configFile = {
    "bat/config".source = "bat/config";
    "bat/themes/base256-brighter.tmTheme".source = "bat/base256-brighter.tmTheme";
  };

  home.packages = with pkgs; [
    bat
  ];

  home.activation.batSetup =
    lib.hm.dag.entryAfter
    ["linkGeneration"]
    ''
      export PATH="${pkgs.bat}/bin:${pkgs.moreutils}/bin:$PATH"
      chronic bat cache --build
    '';
}
