{ config, lib, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      makeSymlinkToRepo
      ;
  in
    {
      home.file = {
        ".profile".source = makeSymlinkToRepo "login-shell/profile.sh";
        ".bash_profile".source = makeSymlinkToRepo "login-shell/bash_profile.bash";
        ".bashrc".source = makeSymlinkToRepo "login-shell/bashrc.bash";
        ".dotfiles/.meta/git_file_watch/active_file_watches/login-shell".source = makeSymlinkToRepo ".meta/git_file_watch/file_watches/login-shell.sh";
        ".zshrc".source = makeSymlinkToRepo "login-shell/zshrc.zsh";
        ".zprofile".source = makeSymlinkToRepo "login-shell/zprofile.zsh";
      };
    }
