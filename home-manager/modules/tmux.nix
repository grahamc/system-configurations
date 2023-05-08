{ config, lib, pkgs, specialArgs, ... }:
  let
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
    # relative to $XDG_CONFIG_HOME
    myTmuxConfigPath = "tmux/my-tmux.conf";
  in
    {
      # Installing the plugins into my profile, instead of using programs.tmux.plugins, for two reasons:
      # - So that I can use the scripts defined in them. (They'll be added to <profile_path>/share/tmux-plugins)
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
          set-environment -g "TMUX_PLUGIN_MANAGER_PATH" "${config.home.profileDirectory}/share/tmux-plugins/"

          source-file ${config.xdg.configHome}/${myTmuxConfigPath}

          ${(lib.strings.concatMapStringsSep "\n\n" (p: ''
            # ${getPluginName p}
            # ---------------------
            ${p.extraConfig or ""}
            run-shell ${if types.package.check p then p.rtp else p.plugin.rtp}
          '') tmuxPlugins)}
        '';
      };

      repository.symlink.xdg.configFile = {
        "fish/conf.d/tmux-integration.fish".source = "tmux/tmux-integration.fish";
        "fish/conf.d/tmux.fish".source = "tmux/tmux.fish";
        ${myTmuxConfigPath}.source = "tmux/tmux.conf";
      };

      repository.symlink.home.file = {
        ".local/bin/tmux-click-url.py".source = "tmux/tmux-click-url.py";
      };

      repository.git.onChange  = [
        {
          patterns.modified = ["tmux/tmux.conf"];
          confirmation = "The tmux configuration has changed, would you like to reload tmux?";
          action = "tmux source-file ~/.config/tmux/tmux.conf";
        }
      ];
    }
