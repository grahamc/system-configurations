{ config, lib, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      runAfterLinkGeneration
      ;
    inherit (specialArgs) isGui;
  in lib.mkIf isGui {
    # TODO: Wezterm doesn't read my config when I link it using `makeSymlinkToRepo`.
    # For now I'll symlink directly into my dotfiles repo. Might have to do with the fact
    # that `makeSymlinkToRepo` links into the Nix store?
    home.activation.weztermSetup = runAfterLinkGeneration ''
      wezterm_config='${config.home.homeDirectory}/.wezterm.lua'
      if [ ! -f $wezterm_config ]; then
        ln --symbolic ${config.home.homeDirectory}/.dotfiles/wezterm/wezterm.lua $wezterm_config
      fi
    '';
  }
