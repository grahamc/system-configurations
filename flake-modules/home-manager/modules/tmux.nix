{
  config,
  lib,
  pkgs,
  specialArgs,
  ...
}: let
  tmuxPlugins = with pkgs.tmuxPlugins; [
    better-mouse-mode
    mode-indicator
    tmux-suspend
    sidebar
  ];

  inherit (lib) types;

  getPluginName = p:
    if types.package.check p
    then p.pname
    else p.plugin.pname;

  # relative to $XDG_CONFIG_HOME
  myTmuxConfigPath = "tmux/my-tmux.conf";
  tmuxReloadScriptName = "${specialArgs.flakeInputs.self}/dotfiles/tmux/bin/tmux-config-reload";

  myTmux = pkgs.symlinkJoin {
    name = "my-${pkgs.tmux.name}";
    paths = [pkgs.tmux];
    buildInputs = [pkgs.makeWrapper];
    # I'm removing $SHELL so tmux will use the OS default shell instead
    # of what it will probably be when I run tmux, fish. This is because
    # the Determinate Systems Nix installer doesn't configure fish
    # properly. When this issue is resolved, I can remove this:
    # https://github.com/DeterminateSystems/nix-installer/issues/576
    postBuild = ''
      wrapProgram $out/bin/tmux --unset SHELL
    '';
  };
in {
  home = {
    # Installing the plugins into my profile, instead of using programs.tmux.plugins, for two
    # reasons:
    #   - So that I can use the scripts defined in them.
    # (They'll be added to <profile_path>/share/tmux-plugins)
    #   - So I can keep the plugin settings in my config. Settings need to be defined before the
    # plugin is loaded and programs.tmux loads my configuration _after_ loading plugins so it
    # wouldn't work. Instead I load them my self.
    packages = with pkgs; [myTmux tmux-xpanes] ++ tmuxPlugins;

    # I reload tmux every time I switch generations because tmux-suspend uses the canonical
    # path to its script when making a key mapping and that path may change when I switch
    # generations.
    activation.reloadTmux =
      lib.hm.dag.entryAfter
      ["linkGeneration"]
      ''
        PATH='${config.home.profileDirectory}/bin:$PATH' ${tmuxReloadScriptName} &
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

      executable."tmux" = {
        source = "tmux/bin";
        recursive = true;
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
