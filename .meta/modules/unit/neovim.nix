{ config, lib, pkgs, specialArgs, ... }:
  {
    home.packages = [
      pkgs.neovim-unwrapped
    ];

    symlink.xdg.configFile = {
      "nvim" = {
        source = "neovim";
        sourcePath = ../../../neovim;
        recursive = true;
      };
    };

    vimPlug.plugfile = ../../../neovim/lua/plugfile.lua;
  }
