{
  config,
  specialArgs,
  pkgs,
  ...
}: let
  inherit (specialArgs) hostName homeDirectory username repositoryDirectory;
  inherit (specialArgs.flakeInputs) self;

  hostctl-switch = pkgs.writeShellApplication {
    name = "hostctl-switch";
    text = ''
      cd "${repositoryDirectory}"

      # Get sudo authentication now so I don't have to wait for it to ask me later
      sudo --validate

      oldGenerationPath="$(readlink --canonicalize ${config.system.profile})"

      darwin-rebuild switch --flake "${repositoryDirectory}#${hostName}" "$@" |& nom

      newGenerationPath="$(readlink --canonicalize ${config.system.profile})"

      cyan='\033[1;0m'
      printf "%bPrinting generation diff...\n" "$cyan"
      nix store diff-closures "$oldGenerationPath" "$newGenerationPath"
    '';
  };

  hostctl-preview-switch = pkgs.writeShellApplication {
    name = "hostctl-preview-switch";
    text = ''
      cd "${repositoryDirectory}"

      oldGenerationPath="$(readlink --canonicalize ${config.system.profile})"

      newGenerationPath="$(nix build --no-link --print-out-paths .#darwinConfigurations.${hostName}.system)"

      cyan='\033[1;0m'
      printf "%bPrinting switch preview...\n" "$cyan"
      nix store diff-closures "$oldGenerationPath" "$newGenerationPath"
    '';
  };

  hostctl-upgrade = pkgs.writeShellApplication {
    name = "hostctl-upgrade";
    text = ''
      cd "${repositoryDirectory}"

      # Get sudo authentication now so I don't have to wait for it to ask me later
      sudo --validate

      oldGenerationPath="$(readlink --canonicalize ${config.system.profile})"

      darwin-rebuild switch --flake "${repositoryDirectory}#${hostName}" ${self.lib.updateFlags.nixDarwin} "$@" |& nom
      chronic nix-upgrade-profiles

      newGenerationPath="$(readlink --canonicalize ${config.system.profile})"

      cyan='\033[1;0m'
      printf "%bPrinting generation diff...\n" "$cyan"
      nix store diff-closures "$oldGenerationPath" "$newGenerationPath"

      # HACK:
      # https://stackoverflow.com/a/40473139
      rm -rf "$(brew --prefix)/var/homebrew/locks"

      chronic brew update
      brew upgrade --greedy
      chronic brew autoremove
      chronic brew cleanup
    '';
  };

  hostctl-preview-upgrade = pkgs.writeShellApplication {
    name = "hostctl-preview-upgrade";
    text = ''
      cd "${repositoryDirectory}"

      oldGenerationPath="$(readlink --canonicalize ${config.system.profile})"

      newGenerationPath="$(nix build --no-write-lock-file ${self.lib.updateFlags.nixDarwin} --no-link --print-out-paths .#darwinConfigurations.${hostName}.system)"

      cyan='\033[1;0m'
      printf "%bPrinting upgrade preview...\n" "$cyan"
      nix store diff-closures "$oldGenerationPath" "$newGenerationPath"

      # HACK:
      # https://stackoverflow.com/a/40473139
      rm -rf "$(brew --prefix)/var/homebrew/locks"

      brew outdated --greedy
    '';
  };
in {
  users.users.${username} = {
    home = homeDirectory;
  };

  environment = {
    systemPackages = [
      hostctl-switch
      hostctl-upgrade
      hostctl-preview-switch
      hostctl-preview-upgrade
    ];
  };

  system = {
    # With Nix's new `auto-allocate-uids` feature, build users get created on demand. This means this check
    # will always fail since the build users won't be present until the build actually starts so I'm disabling
    # the check.
    checks.verifyBuildUsers = false;
  };
}
