{pkgs, ...}: {
  home.packages = with pkgs; [
    gitMinimal
    delta
  ];

  repository.symlink.xdg = {
    configFile = {
      "git/config".source = "git/config";
    };

    executable."git" = {
      source = "git/bin";
      recursive = true;
    };
  };
}
