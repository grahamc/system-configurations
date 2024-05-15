{pkgs, ...}: {
  imports = [
    ../direnv.nix
    ../firefox-developer-edition.nix
    ../git.nix
    ../wezterm.nix
  ];

  home.packages = with pkgs; [
    cloudflared
  ];

  repository.symlink = {
    home.file = {
      ".yashrc".source = "yash/yashrc";
      ".cloudflared/config.yaml".source = "cloudflared/config.yaml";
    };

    xdg.configFile = {
      "ipython/profile_default/ipython_config.py".source = "python/ipython/ipython_config.py";
      "ipython/profile_default/startup" = {
        source = "python/ipython/startup";
      };
    };
  };
}
