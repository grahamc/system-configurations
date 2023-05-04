{ config, lib, specialArgs, ... }:
  {
    symlink.home.file = {
      ".profile".source = "login-shell/profile.sh";
      ".bash_profile".source = "login-shell/bash_profile.bash";
      ".bashrc".source = "login-shell/bashrc.bash";
      ".dotfiles/.meta/git_file_watch/active_file_watches/login-shell".source = ".meta/git_file_watch/file_watches/login-shell.sh";
      ".zshrc".source = "login-shell/zshrc.zsh";
      ".zprofile".source = "login-shell/zprofile.zsh";
    };
  }
