{ config, lib, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeSymlinkToRepo
      ;
  in
    {
      home.file = {
        ".profile".source = makeSymlinkToRepo "login-shell/profile.sh";
        ".bash_profile".source = makeSymlinkToRepo "login-shell/bash_profile.bash";
        ".bashrc".source = makeSymlinkToRepo "login-shell/bashrc.bash";
        ".dotfiles/.meta/git_file_watch/active_file_watches/login-shell".source = makeSymlinkToRepo ".meta/git_file_watch/file_watches/login-shell.sh";
      };
    }
