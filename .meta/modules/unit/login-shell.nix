{ config, lib, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlink
      ;
  in
    {
      home.file = {
        ".profile".source = makeOutOfStoreSymlink "login-shell/profile.sh";
        ".bash_profile".source = makeOutOfStoreSymlink "login-shell/bash_profile.bash";
        ".bashrc".source = makeOutOfStoreSymlink "login-shell/bashrc.bash";
        ".dotfiles/.meta/git_file_watch/active_file_watches/login-shell".source = makeOutOfStoreSymlink ".meta/git_file_watch/file_watches/login-shell.sh";
      };
    }
