{ pkgs, ... }:
  {
    home.packages = with pkgs; [
      neovim-unwrapped
    ];

    repository.symlink.xdg.configFile = {
      "nvim" = {
        source = "neovim";
        recursive = true;
      };
    };

    vimPlug.plugfile = ../dotfiles/neovim/lua/plugfile.lua;
  }
