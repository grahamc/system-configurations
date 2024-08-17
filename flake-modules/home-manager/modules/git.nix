{
  pkgs,
  lib,
  specialArgs,
  ...
}: {
  home.packages = with pkgs; [
    gitMinimal
    delta
  ];

  services.flatpak = lib.attrsets.optionalAttrs (pkgs.stdenv.isLinux && specialArgs.isGui) {
    packages = [
      "com.axosoft.GitKraken"
    ];
  };

  repository.symlink = {
    # For GitKraken:
    # https://feedback.gitkraken.com/suggestions/575407/check-for-git-config-in-xdg_config_homegitconfig-in-addition-to-gitconfig
    home.file = {
      ".gitconfig".source = "git/config";
    };

    xdg = {
      configFile = {
        "git/config".source = "git/config";
      };

      executable."git" = {
        source = "git/bin";
        recursive = true;
      };
    };
  };
}
