{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlinksForTopLevelFiles
      makeOutOfStoreSymlink
      ;

    fishFunctions = makeOutOfStoreSymlinksForTopLevelFiles "fish/my-functions" "fish/functions";
    fishConfigs = makeOutOfStoreSymlinksForTopLevelFiles "fish/conf.d" "fish/conf.d";
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

          source ${makeOutOfStoreSymlink "fish/config.fish"}
        '';
      };

      home.packages = with pkgs; [
        figlet
      ];

      home.file.".dotfiles/.meta/git_file_watch/active_file_watches/fish".source = makeOutOfStoreSymlink ".meta/git_file_watch/file_watches/fish.sh";

      xdg.configFile = {
        "fish/fish_plugins".source = makeOutOfStoreSymlink "fish/fish_plugins";
      } // fishFunctions // fishConfigs;

      xdg.dataFile = {
        "figlet/smblock.tlf".source = makeOutOfStoreSymlink "fish/figlet/smblock.tlf";
      };
    }
