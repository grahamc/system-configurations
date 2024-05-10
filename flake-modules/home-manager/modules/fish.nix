{pkgs, ...}: let
  # relative to $XDG_CONFIG_HOME
  myFishConfigPath = "fish/my-config.fish";
in {
  # Using this so Home Manager can include it's generated completion scripts
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Doing this so that when I reload my fish shell with `exec fish` the config files get read again.
      # The default behaviour is for config files to only be sourced once.
      set --unexport __HM_SESS_VARS_SOURCED
      set --unexport __fish_home_manager_config_sourced

      set xdg_config "''$HOME/.config"
      if set --query XDG_CONFIG_HOME
        set xdg_config "''$XDG_CONFIG_HOME"
      end
      source "''$xdg_config/${myFishConfigPath}"
    '';
    plugins = with pkgs.fishPlugins; [
      {
        name = "autopair-fish";
        src = autopair-fish;
      }
      {
        name = "async-prompt";
        src = async-prompt;
      }
      # Using this to get shell completion for programs added to the path through nix+direnv. Issue to upstream into direnv:
      # https://github.com/direnv/direnv/issues/443
      {
        name = "completion-sync";
        src = completion-sync;
      }
      {
        name = "done";
        src = done;
      }
    ];
  };

  repository = {
    symlink.xdg.configFile = {
      "fish/conf.d" = {
        source = "fish/conf.d";
        recursive = true;
      };
      ${myFishConfigPath}.source = "fish/config.fish";
    };

    git.onChange = [
      {
        patterns.modified = [''^dotfiles/fish/conf\.d/'' ''^dotfiles/fish/config.fish$''];
        action = ''
          echo "The fish shell configuration has changed. To apply these changes you should restart any running terminals. Press enter to continue"

          # To hide any keys the user may press before enter I disable echo. After prompting them, I re-enable it.
          stty_original="$(stty -g)"
          stty -echo
          # I don't care if read mangles backslashes since I'm not using the input anyway.
          # shellcheck disable=2162
          read _unused
          stty "$stty_original"
        '';
      }
    ];
  };
}
