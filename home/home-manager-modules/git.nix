{ config, lib, pkgs, specialArgs, ... }:
  {
    home.packages = with pkgs; [
      git
      delta
      gitui
    ];

    repository.symlink.home.file = {
      # I link to this directory from other modules so I make sure the key here is unique and specify the target
      # inside the attribute set.
      ".local/bin (git)" = {
        target = ".local/bin";
        source = "git/subcommands";
        recursive = true;
      };
    };

    repository.symlink.xdg.configFile = {
      "gitui/theme.ron".source = "git/gitui/theme.ron";
      "git/config".source = "git/gitconfig";
    };
  }
