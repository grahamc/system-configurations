{
  lib,
  pkgs,
  specialArgs,
  ...
}: let
  inherit (specialArgs) isGui;
  inherit (lib.attrsets) optionalAttrs;
in
  # TODO: Instead of wrapping terminfo and placing its database in ~/.terminfo, I think I can just
  # add ~/.nix-profile/share/terminfo to $TERMINFO_DIRS in my login profile (maybe the nix installer
  # should do this), but I'm too lazy to test this. May be a problem with flatpak as I'm not sure if
  # it will inherit $TERMINFO_DIRS.
  #
  # Also how does terminfo work with SSH, should I be bundling my terminfos in my portable home? I
  # think for SSH I need to set TERMINFO_DIRS in the shell and add an entry to the database in my
  # bundle.
  #
  # There are some good ideas here on what a better system could look like:
  # https://github.com/fish-shell/fish-shell/pull/10269
  #
  # Or maybe SSH could add an option for copying the host terminfo to the remote and setting
  # TERMINFO_DIRS in the remote. Maybe I could do this in a `RemoteCommand`. Looks like Kitty agrees
  # with this approach and also has a good workaround to use in the interim:
  # https://sw.kovidgoyal.net/kitty/kittens/ssh/#copying-terminfo-files-manually
  optionalAttrs isGui {
    home.packages = with pkgs; [
      # ncurses doesn't come with wezterm's terminfo so I need to use the one from my overlay.
      # Also macOS comes with a very old version of ncurses that doesn't have a terminfo entry
      # for tmux, tmux-256color, either.
      ncursesWithWezterm
    ];

    home.file = {
      # Since environment variables from the login shell don't get inherited by apps in macOS,
      # my terminal will use the system ncurses, which doesn't have an entry for wezterm. To
      # work around this, I have to put the wezterm terminfo in a place where the system ncurses
      # will find it.
      #
      # Wezterm also needs it when running in flatpak.
      ".terminfo" = {
        source = "${pkgs.ncursesWithWezterm}/share/terminfo/";
        recursive = true;
      };
    };

    repository.symlink.xdg.configFile = {
      "wezterm/wezterm.lua".source = "wezterm/wezterm.lua";
    };
  }
