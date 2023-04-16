{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeSymlinkToRepo
      ;
  in
    {
      programs.neovim = {
        enable = true;
        plugins = with pkgs.vimPlugins; [
          nvim-treesitter.withAllGrammars
          telescope-fzf-native-nvim
          vim-plug
        ];
        withRuby = false;
        withPython3 = false;
      };

      home.file = {
        ".dotfiles/.meta/git_file_watch/active_file_watches/neovim".source = makeSymlinkToRepo ".meta/git_file_watch/file_watches/neovim.sh";
        # The Home Manager nvim wrapper always passes a few args to nvim. To be able to tell when _I_ passed an
        # argument, I made another wrapper.
        ".local/bin/nvim" = {
          executable = true;
          text = ''
            #!/bin/bash

            if test "$#" -eq 0; then
              NEOVIM_FORCE_SESSION_MODE=1 ~/.nix-profile/bin/nvim "$@"
            else
              ~/.nix-profile/bin/nvim "$@"
            fi
          '';
        };
      };

      xdg.configFile = {
        "nvim/init.lua".source = makeSymlinkToRepo "neovim/init.lua";
        "nvim/plugfile-lock.vim".source = makeSymlinkToRepo "neovim/plugfile-lock.vim";
        "nvim/plugfile.lua".source = makeSymlinkToRepo "neovim/plugfile.lua";
        "nvim/profiles".source = makeSymlinkToRepo "neovim/profiles";
        "nvim/lua".source = makeSymlinkToRepo "neovim/lua";
      };

      xdg.dataFile."nvim/site/autoload/plug.vim".source = "${pkgs.vimPlugins.vim-plug}/plug.vim";
    }
