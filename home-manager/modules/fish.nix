{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (specialArgs) xdgPkgs;
    myFishConfigPath = "fish/my-config.fish";
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

          source ${config.xdg.configHome}/${myFishConfigPath}
        '';
        plugins = with pkgs.fishPlugins; [
          {name = "autopair-fish"; src = autopair-fish;}
          {name = "async-prompt"; src = async-prompt;}
        ];
      };

      home.packages = [
        xdgPkgs.figlet
      ];

      symlink.xdg.configFile = {
        "fish/conf.d" = {
          source = "fish/conf.d";
          sourcePath = ../../fish/conf.d;
          recursive = true;
        };
        ${myFishConfigPath}.source = "fish/config.fish";
      };

      symlink.xdg.dataFile = {
        "figlet/smblock.tlf".source = "fish/figlet/smblock.tlf";
      };

      gitRepository.onChangeHandlers = [
        {
          patterns.modified = ["fish/functions/*" "fish/conf.d/*"];
          confirmation = "A fish configuration or function has changed, would you like to reload all fish shells?";
          action = ''
            fish -c 'set --universal _fish_reload_indicator (random)'
          '';
        }
      ];
    }
