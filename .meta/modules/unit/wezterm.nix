{ config, lib, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlink
      ;
    inherit (specialArgs) isGui;
  in lib.mkIf isGui {
    home.file = {
      ".wezterm.lua".source = makeOutOfStoreSymlink "wezterm/wezterm.lua";
    };
  }
