{pkgs, ...}: {
  home.packages = with pkgs; [
    direnv
  ];

  repository.symlink.xdg.configFile = {
    "direnv/direnv.toml".source = "direnv/direnv.toml";
  };

  xdg.configFile = {
    "fish/conf.d/direnv.fish".source = ''${
        pkgs.runCommand "direnv-config.fish" {} "${pkgs.direnv}/bin/direnv hook fish > $out"
      }'';
  };
}
