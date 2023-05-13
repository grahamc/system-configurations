{ pkgs, config, ... }:
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

    vimPlug.plugfile = config.repository.directoryPath + "/dotfiles/neovim/lua/plugfile.lua"; 
    
  }
