{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      makeSymlinkToRepo
      ;
    tmuxPlugins = with pkgs.tmuxPlugins; [
      better-mouse-mode
      resurrect
      mode-indicator
      tmux-suspend

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

      xdg.configFile = {
        "tmux/tmux.conf".text = ''
          # This is where my config expects plugins to be in order to access their scripts
          # My old tmux plugin manager, TPM, would set this environment variable to the path where plugins were stored.
          # Though I use Nix to manage my plugins now, this variable is referenced all over my tmux.conf so I'll
          # set the variable here to not break anything.
          set-environment -g "TMUX_PLUGIN_MANAGER_PATH" "${config.home.homeDirectory}/.nix-profile/share/tmux-plugins/"

          source-file ${makeSymlinkToRepo "tmux/tmux.conf"}

          ${(lib.strings.concatMapStringsSep "\n\n" (p: ''
            # ${getPluginName p}
            # ---------------------
            ${p.extraConfig or ""}
            run-shell ${if types.package.check p then p.rtp else p.plugin.rtp}
          '') tmuxPlugins)}
        '';
        "fish/conf.d/tmux-integration.fish".source = makeSymlinkToRepo "tmux/tmux-integration.fish";
        "fish/conf.d/tmux.fish".source = makeSymlinkToRepo "tmux/tmux.fish";
      };

      home.file = {
        ".local/bin/tmux-click-url.py".source = makeSymlinkToRepo "tmux/tmux-click-url.py";
        ".dotfiles/.meta/git_file_watch/active_file_watches/tmux".source = makeSymlinkToRepo ".meta/git_file_watch/file_watches/tmux.sh";
      };
    }
