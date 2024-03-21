{pkgs, ...}: {
  home.packages = with pkgs; [
    gitMinimal
    delta
    gitui
  ];

  repository.symlink.xdg.executable = {
    "git executables" = {
      source = "git/subcommands";
      recursive = true;
    };
  };

  repository.symlink.xdg.configFile = {
    "git/config".source = "git/config";
    "gitui/theme.ron".source = "gitui/theme.ron";
  };
}
