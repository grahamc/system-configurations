{ config, lib, pkgs, specialArgs, ... }:
  {
    home.packages = with pkgs; [
      gitMinimal
      delta
    ];

    repository.symlink.xdg.executable = {
      "git executables" = {
        source = "git/subcommands";
        recursive = true;
      };
    };

    repository.symlink.xdg.configFile = {
      "git/config".source = "git/gitconfig";
    };
  }
