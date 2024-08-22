{
  lib,
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) isGui;
  inherit (lib.attrsets) optionalAttrs;
in
  optionalAttrs isGui {
    home.packages = with pkgs; [
      ncurses
    ];

    services.flatpak = lib.attrsets.optionalAttrs (pkgs.stdenv.isLinux && specialArgs.isGui) {
      packages = [
        "org.wezfurlong.wezterm"
      ];
    };

    home.file = {
      # Putting my terminfo database here so it gets picked up[2].
      #
      # Ideally, whatever program sets TERM, e.g. wezterm, also
      # sets TERMINFO to the base64 encoded terminfo[2]. This way we don't need
      # a database at all and SSH can just copy TERMINFO to the remote host.
      #
      # [1]: https://github.com/fish-shell/fish-shell/pull/10269
      # [2]: https://invisible-island.net/ncurses/man/ncurses.3x.html#h3-TERMINFO
      ".terminfo" = {
        source = "${pkgs.myTerminfoDatabase}/share/terminfo";
      };
    };

    repository.symlink.xdg.configFile = {
      "wezterm/wezterm.lua".source = "wezterm/wezterm.lua";
    };
  }
