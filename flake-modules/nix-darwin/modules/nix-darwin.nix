{
  config,
  specialArgs,
  pkgs,
  ...
}: let
  inherit (specialArgs) hostName homeDirectory username repositoryDirectory;

  hostctl-preview-switch = pkgs.writeShellApplication {
    name = "hostctl-preview-switch";
    runtimeInputs = with pkgs; [nix coreutils];
    text = ''
      cd "${repositoryDirectory}"

      oldGenerationPath="$(readlink --canonicalize ${config.system.profile})"

      newGenerationPath="$(nix build --no-link --print-out-paths .#darwinConfigurations.${hostName}.system)"

      cyan='\033[1;0m'
      printf "%bPrinting switch preview...\n" "$cyan"
      nix store diff-closures "$oldGenerationPath" "$newGenerationPath"
    '';
  };

  hostctl-switch = pkgs.writeShellApplication {
    name = "hostctl-switch";
    runtimeInputs = with pkgs; [nix nix-output-monitor coreutils];
    text = ''
      cd "${repositoryDirectory}"

      # Get sudo authentication now so I don't have to wait for it to ask me later
      sudo --validate

      oldGenerationPath="$(readlink --canonicalize ${config.system.profile})"

      ${config.system.profile}/sw/bin/darwin-rebuild switch --flake "${repositoryDirectory}#${hostName}" "$@" |& nom

      newGenerationPath="$(readlink --canonicalize ${config.system.profile})"

      cyan='\033[1;0m'
      printf "%bPrinting generation diff...\n" "$cyan"
      nix store diff-closures "$oldGenerationPath" "$newGenerationPath"
    '';
  };

  hostctl-upgrade = pkgs.writeShellApplication {
    name = "hostctl-upgrade";
    runtimeInputs = with pkgs; [coreutils gitMinimal less direnv nix];
    text = ''
      # TODO: So `just` has access to `hostctl-switch`, not a great solution
      PATH="${config.system.profile}/sw/bin:$PATH"
      cd "${repositoryDirectory}"

      rm -f ~/.local/state/nvim/*.log
      rm -f ~/.local/state/nvim/undo/*

      git fetch
      if [ -n "$(git log 'HEAD..@{u}' --oneline)" ]; then
          echo "$(echo 'Commits made since last pull:'$'\n'; git log '..@{u}')" | less

          if [ -n "$(git status --porcelain)" ]; then
              git stash --include-untracked --message 'Stashed for upgrade'
          fi

          direnv allow
          direnv exec "$PWD" nix-direnv-reload
          direnv exec "$PWD" git pull
      else
          # Something probably went wrong so we're trying to upgrade again even
          # though there's nothing to pull. In which case, just run the hook as
          # though we did.
          direnv allow
          direnv exec "$PWD" nix-direnv-reload
          direnv exec "$PWD" lefthook run post-rewrite
      fi

      # HACK:
      # https://stackoverflow.com/a/40473139
      rm -rf "$(/usr/local/bin/brew --prefix)/var/homebrew/locks"

      /usr/local/bin/brew update
      /usr/local/bin/brew upgrade --greedy
      /usr/local/bin/brew autoremove
      /usr/local/bin/brew cleanup
    '';
  };

  update-check =
    pkgs.writeShellApplication
    {
      name = "update-check";
      runtimeInputs = with pkgs; [coreutils gitMinimal terminal-notifier];
      text = ''
        log="$(mktemp --tmpdir 'nix_darwin_update_XXXXX')"
        exec 2>"$log" 1>"$log"
        trap 'terminal-notifier -title "Nix Darwin" -message "Update check failed :( Check the logs in $log"' ERR

        cd "${repositoryDirectory}"

        git fetch
        if [ -n "$(git log 'HEAD..@{u}' --oneline)" ]; then
          terminal-notifier -title "Nix Darwin" -message "Updates are available, click here to update." -execute '/usr/local/bin/wezterm --config "default_prog={[[${hostctl-upgrade}/bin/hostctl-upgrade]]}" --config "exit_behavior=[[Hold]]"'
        fi
      '';
    };
in {
  configureLoginShellForNixDarwin = true;

  users.users.${username} = {
    home = homeDirectory;
  };

  environment = {
    systemPackages = [
      hostctl-preview-switch
      hostctl-switch
      hostctl-upgrade
    ];
  };

  system = {
    # With Nix's new `auto-allocate-uids` feature, build users get created on
    # demand. This means this check will always fail since the build users won't
    # be present until the build actually starts so I'm disabling the check.
    checks.verifyBuildUsers = false;
  };

  launchd.user.agents.nix-darwin-update-check = {
    serviceConfig.RunAtLoad = false;

    serviceConfig.StartCalendarInterval = [
      # once a day at 6am
      {Hour = 6;}
    ];

    command = ''${update-check}/bin/update-check'';
  };
}
