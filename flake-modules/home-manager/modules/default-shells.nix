_: {
  repository = {
    symlink.home.file = {
      ".bash_profile".source = "default-shells/bash_profile.bash";
      ".bashrc".source = "default-shells/bashrc.bash";
      ".zshrc".source = "default-shells/zshrc.zsh";
      ".zlogin".source = "default-shells/zlogin.zsh";
    };

    symlink.xdg.configFile = {
      "default-shells/login-config.sh".source = "default-shells/login-config.sh";
    };

    git.onChange = [
      {
        patterns.modified = [''^dotfiles/default-shells/login-config\.sh$''];
        action = ''
          echo "The login shell configuration has changed. To apply these changes you can log out. Press enter to continue (This will not log you out)"

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
