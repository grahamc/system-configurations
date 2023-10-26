{ pkgs, config, specialArgs, ... }:
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

    xdg.dataFile = {
      "nvim/types".source = "${specialArgs.flakeInputs.neodev-nvim}/types/stable";
    };

    vimPlug.configDirectory = config.repository.directoryPath + "/dotfiles/neovim/lua"; 
    
  }
