{ config, specialArgs, pkgs, ... }: let
  inherit (specialArgs) hostName homeDirectory username repositoryDirectory;
  inherit (specialArgs.flakeInputs) self;

  hostctl-switch = pkgs.writeShellApplication {
    name = "hostctl-switch";
    runtimeInputs = with pkgs; [coreutils-full];
    text = ''
      cd "${repositoryDirectory}"

      # Get sudo authentication now so I don't have to wait for it to ask me later
      sudo --validate

      oldGenerationPath="''$(readlink --canonicalize ${config.system.profile})"

      darwin-rebuild switch --flake "${repositoryDirectory}#${hostName}" "''$@" |& nom

      newGenerationPath="''$(readlink --canonicalize ${config.system.profile})"

      cyan='\033[1;0m'
      printf "%bPrinting generation diff...\n" "$cyan"
      nix store diff-closures "''$oldGenerationPath" "''$newGenerationPath"
    '';
  };

  hostctl-upgrade = pkgs.writeShellApplication {
    name = "hostctl-upgrade";
    runtimeInputs = with pkgs; [coreutils-full];
    text = ''
      cd "${repositoryDirectory}"

      # Get sudo authentication now so I don't have to wait for it to ask me later
      sudo --validate

      oldGenerationPath="''$(readlink --canonicalize ${config.system.profile})"

      darwin-rebuild switch --flake "${repositoryDirectory}#${hostName}" ${self.lib.updateFlags.darwin} "''$@" |& nom
      nix-upgrade-profiles

      brew update
      brew upgrade --greedy
      brew autoremove
      brew cleanup

      newGenerationPath="''$(readlink --canonicalize ${config.system.profile})"

      cyan='\033[1;0m'
      printf "%bPrinting generation diff...\n" "$cyan"
      nix store diff-closures "''$oldGenerationPath" "''$newGenerationPath"
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
    ];
  };

  system = {
    # With Nix's new `auto-allocate-uids` feature, build users get created on demand. This means this check
    # will always fail since the build users won't be present until the build actually starts so I'm disabling
    # the check.
    checks.verifyBuildUsers = false;
  };
}
