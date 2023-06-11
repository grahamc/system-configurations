{ config, lib, pkgs, specialArgs, ... }:
  {
    home.packages = with pkgs; [
      gitMinimal
      delta
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
      "git/config".source = "git/gitconfig";
    };
  }
