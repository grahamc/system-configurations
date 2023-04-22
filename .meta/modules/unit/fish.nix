{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      makeSymlinksToTopLevelFilesInRepo
      makeSymlinkToRepo
      ;

    fishFunctions = makeSymlinksToTopLevelFilesInRepo "fish/my-functions" "fish/functions" ../../../fish/functions;
    fishConfigs = makeSymlinksToTopLevelFilesInRepo "fish/conf.d" "fish/conf.d" ../../../fish/conf.d;
  in
    {
      # Using this so HM can include it's generated completion scripts
      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          # Doing this so that when I reload my fish shell with `exec fish` the config files get read again.
          # The default behaviour is for config files to only be sourced once.
          set --unexport __HM_SESS_VARS_SOURCED
          set --unexport __fish_home_manager_config_sourced

          # Remove Home Manager's command-not-found handler
          functions --erase __fish_command_not_found_handler

          source ${makeSymlinkToRepo "fish/config.fish"}
        '';
        # TODO: Some plugins, such as fish-abbreviation-tips, expect an event that `fisher` emits whenever it
        # installs a plugin, <plugin_name>_install, to do setup. Home manager doesn't emit that event so
        # for now I'm manually calling the setup functions in my config.fish.
        plugins = with pkgs.fishPlugins; [
          {name = "fish-abbreviation-tips"; src = fish-abbreviation-tips;}
          {name = "autopair-fish"; src = autopair-fish;}
          {name = "async-prompt"; src = async-prompt;}
        ];
      };

      home.packages = with pkgs; [
        figlet
      ];

      home.file.".dotfiles/.meta/git_file_watch/active_file_watches/fish".source = makeSymlinkToRepo ".meta/git_file_watch/file_watches/fish.sh";

      xdg.configFile = fishFunctions // fishConfigs;

      xdg.dataFile = {
        "figlet/smblock.tlf".source = makeSymlinkToRepo "fish/figlet/smblock.tlf";
      };
    }
