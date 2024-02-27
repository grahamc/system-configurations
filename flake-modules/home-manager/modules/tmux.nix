{
  config,
  lib,
  pkgs,
  ...
}: let
  tmuxPlugins = with pkgs.tmuxPlugins; [
    better-mouse-mode
    resurrect
    mode-indicator
    tmux-suspend

    # NOTE: continuum must be the last plugin listed:
    # https://github.com/tmux-plugins/tmux-continuum#known-issues
    continuum
  ];
  inherit (lib) types;
  getPluginName = p:
    if types.package.check p
    then p.pname
    else p.plugin.pname;
  # relative to $XDG_CONFIG_HOME
  myTmuxConfigPath = "tmux/my-tmux.conf";
  tmuxReloadScriptName = "tmux-config-reload";
  tmux =
    pkgs.writeShellScriptBin
    "tmux"
    # I want the $SHLVL to start from one for any shells launched in TMUX since they
    # technically aren't children of the shell that I launched TMUX with. I would do this
    # with TMUX's `default-command`, but that may break tmux-resurrect, as explained in my
    # tmux.conf.
    #
    # I am removing $SHELL so tmux will use the OS default shell instead of what it will probably be
    # when I run tmux, fish. This is because the Determinate Systems Nix installer doesn't configure
    # fish properly. When this issue is resolved, I can remove this:
    # https://github.com/DeterminateSystems/nix-installer/issues/576
    ''
      exec env -u SHLVL -u SHELL ${pkgs.tmux}/bin/tmux "$@"
    '';
in {
  home = {
    # Installing the plugins into my profile, instead of using programs.tmux.plugins, for two
    # reasons:
    #   - So that I can use the scripts defined in them.
    # (They'll be added to <profile_path>/share/tmux-plugins)
    #   - So I can keep the plugin settings in my config. Settings need to be defined before the
    # plugin is loaded and programs.tmux loads my configuration _after_ loading plugins so it
    # wouldn't work. Instead I load them my self.
    packages = [tmux] ++ tmuxPlugins;

    # I reload tmux every time I switch generations because tmux-suspend uses the canonical
    # path to its script when making a key mapping and that path may change when I switch
    # generations.
    activation.reloadTmux =
      lib.hm.dag.entryAfter
      ["linkGeneration"]
      ''
        PATH='${config.repository.symlink.xdg.executableHome}:${config.home.profileDirectory}/bin:$PATH' ${tmuxReloadScriptName} &
      '';
  };

  xdg.configFile = {
    "tmux/tmux.conf".text = ''
      # This is where my config expects plugins to be in order to access their scripts
      # My old tmux plugin manager, TPM, would set this environment variable to the path
      # where plugins were stored. Though I use Nix to manage my plugins now, this variable is
      # referenced all over my tmux.conf so I'll set the variable here to not break anything.
      set-environment -g \
        "TMUX_PLUGIN_MANAGER_PATH" \
        "${config.home.profileDirectory}/share/tmux-plugins/"

      run-shell 'tmux source-file "''${XDG_CONFIG_HOME:-''$HOME/.config}/${myTmuxConfigPath}"'

      ${(lib.strings.concatMapStringsSep "\n\n" (p: ''
          # ${getPluginName p}
          # ---------------------
          ${p.extraConfig or ""}
          run-shell ${
            if types.package.check p
            then p.rtp
            else p.plugin.rtp
          }
        '')
        tmuxPlugins)}
    '';
  };

  repository = {
    symlink.xdg = {
      configFile = {
        "fish/conf.d/tmux.fish".source = "tmux/tmux.fish";
        ${myTmuxConfigPath}.source = "tmux/tmux.conf";
      };

      executable = {
        "tmux-click-url".source = "tmux/tmux-click-url.py";
        "tmux-last-command-output".source = "tmux/tmux-last-command-output.bash";
        ${tmuxReloadScriptName}.source = "tmux/${tmuxReloadScriptName}.bash";
        "tmux-attach-to-project".source = "tmux/tmux-attach-to-project.fish";
      };
    };

    git.onChange = [
      {
        patterns.modified = [''^dotfiles/tmux/tmux\.conf$''];
        confirmation = "The tmux configuration has changed, would you like to reload tmux?";
        action = tmuxReloadScriptName;
      }
    ];
  };
}
