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

    vimPlug.configDirectory = config.repository.directoryPath + "/dotfiles/neovim/lua"; 
    
  }
