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

      home.file.".dotfiles/.meta/git_file_watch/active_file_watches/neovim".source = makeSymlinkToRepo ".meta/git_file_watch/file_watches/neovim.sh";

      xdg.configFile = {
        "nvim/init.lua".source = makeSymlinkToRepo "neovim/init.lua";
        "nvim/plugfile.vim".source = makeSymlinkToRepo "neovim/plugfile.vim";
        "nvim/plugfile-lock.vim".source = makeSymlinkToRepo "neovim/plugfile-lock.vim";
        "nvim/profiles".source = makeSymlinkToRepo "neovim/profiles";
      };

      xdg.dataFile."nvim/site/autoload/plug.vim".source = "${pkgs.vimPlugins.vim-plug}/plug.vim";
    }
