{ config, lib, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlink
      runAfterLinkGeneration
      ;
    inherit (specialArgs) isGui;
  in lib.mkIf isGui {
    # TODO: Wezterm doesn't read my config when I link it using `makeOutOfStoreSymlink`.
    # For now I'll symlink directly into my dotfiles repo. Might have to do with the fact
    # that `makeOutOfStoreSymlink` links into the Nix store?
    home.activation.weztermSetup = runAfterLinkGeneration ''
      wezterm_config='/home/biggs/.wezterm.lua'
      if [ ! -f $wezterm_config ]; then
        ln --symbolic /home/biggs/.dotfiles/wezterm/wezterm.lua $wezterm_config
      fi
    '';
  }
