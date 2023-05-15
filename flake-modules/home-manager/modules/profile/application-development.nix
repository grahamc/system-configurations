{ config, lib, pkgs, specialArgs, ... }:
  {
    imports = [
      ../direnv.nix
      ../firefox-developer-edition.nix
      ../git.nix
    ];

    home.packages = with pkgs; [
      (python3.withPackages(ps: with ps; [pip mypy ipython]))
      nodejs
      rustc
      cargo
      jdk
      lua
      bashInteractive
      yash
      cloudflared
      timg
      xdgWrappers.watchman
      nil
      pynix
    ];

    repository.symlink.home.file = {
      ".ipython/profile_default/ipython_config.py".source = "python/ipython/ipython_config.py";
      ".yashrc".source = "yash/yashrc";
      ".cloudflared/config.yaml".source = "cloudflared/config.yaml";
      ".markdownlint.jsonc".source = "markdownlint/markdownlint.jsonc";
      ".vale.ini".source = "vale/vale.ini";
      ".ipython/profile_default/startup" = {
        source = "python/ipython/startup";
        recursive = true;
      };
    };

    repository.symlink.xdg.configFile = {
      "pip/pip.conf".source = "python/pip/pip.conf";
      "vale/styles/base".source = "vale/styles/base";
      "vale/styles/ignore.txt".source = "vale/styles/ignore.txt";
    };
  }
