{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeSymlinkToRepo
      ;
    tmux-suspend = (pkgs.tmuxPlugins.mkTmuxPlugin {
      pluginName = "suspend";
      version = "unstable-2023-01-15";
      src = pkgs.fetchFromGitHub {
        owner = "MunifTanjim";
        repo = "tmux-suspend";
        rev = "1a2f806666e0bfed37535372279fa00d27d50d14";
        sha256 = "0j7vjrwc7gniwkv1076q3wc8ccwj42zph5wdmsm9ibz6029wlmzv";
      };
    });
    tmux-volume = (pkgs.tmuxPlugins.mkTmuxPlugin {
      pluginName = "volume";
      version = "unstable-2018-10-02";
      src = pkgs.fetchFromGitHub {
        owner = "levex";
        repo = "tmux-plugin-volume";
        rev = "4e4032d2fc3283e031334467cd3a4fd0abe73078";
        sha256 = "0big068pj6xl9s1l1bwjmy0d29pv9v93v55cn459mhhz82xv90y7";
      };
    });
    tmuxPlugins = with pkgs.tmuxPlugins; [
      better-mouse-mode
      (resurrect.overrideAttrs (oldAttrs: {
        version = "unstable-2023-05-06";
        src = pkgs.fetchFromGitHub {
          owner = "tmux-plugins";
          repo = "tmux-resurrect";
          rev = "cff343cf9e81983d3da0c8562b01616f12e8d548";
          sha256 = "0djfz7m4l8v2ccn1a97cgss5iljhx9k2p8k9z50wsp534mis7i0m";
        };
      }))
      mode-indicator
      battery
      online-status
      # NOTE: continuum must be the last plugin listed: https://github.com/tmux-plugins/tmux-continuum#known-issues
      continuum
      tmux-suspend
      tmux-volume
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
        ".dotfiles/.meta/git_file_watch/active_file_watches/tmux".source = makeSymlinkToRepo ".meta/git_file_watch/file_watches/tmux.sh";
      };
    }
