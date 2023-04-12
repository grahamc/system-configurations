{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeSymlinkToRepo
      ;
    tmuxPlugins = with pkgs.tmuxPlugins; [
      better-mouse-mode
      resurrect
      mode-indicator
      battery
      online-status
      # NOTE: continuum must be the last plugin listed: https://github.com/tmux-plugins/tmux-continuum#known-issues
      continuum
    ];
    inherit (lib) types;
    getPluginName = p: if types.package.check p then p.pname else p.plugin.pname;
  in
    {
      # Installing the plugins into my profile, instead of using programs.tmux.plugins, for two reasons:
      # - So that I can use the scripts defined in them. (They'll be added to ~/.nix-profile/share/tmux-plugins)
      # - So I can keep the plugin settings in my config. Settings need to be defined before the plugin is loaded
      # and programs.tmux loads my configuration _after_ loading plugins so it wouldn't work. Instead I load
      # them my self.
      home.packages = with pkgs; [
        tmux
      ] ++ tmuxPlugins;

      xdg.configFile."tmux/tmux.conf".text = ''
        source-file ${makeSymlinkToRepo "tmux/tmux.conf"}

        # This is where my config expects plugins to be in order to access their scripts
        set-environment -g "TMUX_PLUGIN_MANAGER_PATH" "${config.home.homeDirectory}/.nix-profile/share/tmux-plugins/"

        ${(lib.strings.concatMapStringsSep "\n\n" (p: ''
          # ${getPluginName p}
          # ---------------------
          ${p.extraConfig or ""}
          run-shell ${if types.package.check p then p.rtp else p.plugin.rtp}
        '') tmuxPlugins)}
      '';

      home.file = {
        ".local/bin/tmux-nest".source = makeSymlinkToRepo "tmux/tmux-nest";
        ".local/bin/tmux-click-url.py".source = makeSymlinkToRepo "tmux/tmux-click-url.py";
      };
    }
