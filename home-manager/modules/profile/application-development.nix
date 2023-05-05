{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (specialArgs) xdgPkgs;
  in
    {
      imports = [
        ../direnv.nix
        ../firefox-developer-edition.nix
        ../git.nix
        ../wezterm.nix
        ../keyboard-shortcuts.nix
        ../fonts.nix
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
        xdgPkgs.watchman
        nil
      ];

      repository.symlink.home.file = {
        ".ipython/profile_default/ipython_config.py".source = "python/ipython/ipython_config.py";
        ".yashrc".source = "yash/yashrc";
        ".cloudflared/config.yaml".source = "cloudflared/config.yaml";
        ".markdownlint.jsonc".source = "markdownlint/markdownlint.jsonc";
        ".vale.ini".source = "vale/vale.ini";
        ".ipython/profile_default/startup" = {
          source = "python/ipython/startup";
          sourcePath = ../../../python/ipython/startup;
          recursive = true;
        };
      };

      home.file = {
        ".local/bin/pynix" = {
          text = ''
            #!${pkgs.fish}/bin/fish

            set packages (printf %s\n $argv | xargs -I PACKAGE echo "python3Packages.PACKAGE")
            ${pkgs.any-nix-shell}/bin/.any-nix-shell-wrapper fish -p $packages

          '';
          executable = true;
        };
      };

      repository.symlink.xdg.configFile = {
        "pip/pip.conf".source = "python/pip/pip.conf";
        "vale/styles/base".source = "vale/styles/base";
        "vale/styles/ignore.txt".source = "vale/styles/ignore.txt";
      };
    }
