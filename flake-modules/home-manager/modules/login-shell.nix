{ ... }:
  {
    repository.symlink.home.file = {
      ".profile".source = "login-shell/profile.sh";
      ".bash_profile".source = "login-shell/bash_profile.bash";
      ".bashrc".source = "login-shell/bashrc.bash";
      ".zshrc".source = "login-shell/zshrc.zsh";
      ".zprofile".source = "login-shell/zprofile.zsh";
    };

    repository.git.onChange = [
      {
        patterns.modified = ["*login-shell/profile.sh"];
        action = ''
          echo "The login shell profile has changed. To apply these changes you can log out. Press enter to continue (This will not log you out)"

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
  }
