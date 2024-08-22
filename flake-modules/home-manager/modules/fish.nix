{
  pkgs,
  config,
  lib,
  ...
}: {
  # Using this so Home Manager can include it's generated completion scripts
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Doing this so that when I reload my fish shell with `exec fish` the config files get read again.
      # The default behaviour is for config files to only be sourced once.
      set --unexport __HM_SESS_VARS_SOURCED
      set --unexport __fish_home_manager_config_sourced

      fish_add_path --global --prepend --move ${lib.escapeShellArg config.repository.symlink.xdg.executableHome}
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
        # I'm recursively linking because I link into this directory in other
        # places.
        recursive = true;
      };
    };

    git.onChange = [
      {
        patterns.modified = [''^dotfiles/fish/conf\.d/''];
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
