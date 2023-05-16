{ config, lib, pkgs, specialArgs, ... }:
  let
    symlinkToMyFishConfig = config.lib.file.mkOutOfStoreSymlink
      "${config.repository.symlink.baseDirectory}/fish/config.fish";
  in
    {
      # Using this so Home Manager can include it's generated completion scripts
      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          # Doing this so that when I reload my fish shell with `exec fish` the config files get read again.
          # The default behaviour is for config files to only be sourced once.
          set --unexport __HM_SESS_VARS_SOURCED
          set --unexport __fish_home_manager_config_sourced

          # Remove Home Manager's command-not-found handler
          functions --erase __fish_command_not_found_handler

          source '${symlinkToMyFishConfig}'
        '';
        plugins = with pkgs.fishPlugins; [
          {name = "autopair-fish"; src = autopair-fish;}
          {name = "async-prompt"; src = async-prompt;}
        ];
      };

      home.packages = [
        pkgs.xdgWrappers.figlet
      ];

      repository.symlink.xdg.configFile = {
        "fish/conf.d" = {
          source = "fish/conf.d";
          recursive = true;
        };
      };

      repository.symlink.xdg.dataFile = {
        "figlet/smblock.tlf".source = "fish/figlet/smblock.tlf";
      };

      repository.git.onChange = [
        {
          patterns.modified = ["*fish/functions/*" "*fish/conf.d/*"];
          confirmation = "A fish configuration or function has changed, would you like to reload all fish shells?";
          action = ''
            fish -c 'set --universal _fish_reload_indicator (random)'
          '';
        }
      ];
    }
