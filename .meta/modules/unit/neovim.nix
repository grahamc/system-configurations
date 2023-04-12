{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlink
      ;
  in
    {
      programs.neovim = {
        enable = true;
        plugins = with pkgs.vimPlugins; [
          nvim-treesitter.withAllGrammars
          telescope-fzf-native-nvim
        ];
        withRuby = false;
        withPython3 = false;
      };

      home.file.".dotfiles/.meta/git_file_watch/active_file_watches/neovim".source = makeOutOfStoreSymlink ".meta/git_file_watch/file_watches/neovim.sh";

      xdg.configFile = {
        "nvim/init.lua".source = makeOutOfStoreSymlink "neovim/init.lua";
        "nvim/plugfile.vim".source = makeOutOfStoreSymlink "neovim/plugfile.vim";
        "nvim/plugfile-lock.vim".source = makeOutOfStoreSymlink "neovim/plugfile-lock.vim";
        "nvim/profiles".source = makeOutOfStoreSymlink "neovim/profiles";
      };
    }
