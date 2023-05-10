{ config, lib, specialArgs, pkgs, ... }:
  let
    inherit (specialArgs) hostName homeDirectory username repositoryDirectory updateFlags;

    # Scripts for switching generations and upgrading flake inputs.
    packages = [
      (pkgs.writeShellApplication {
        name = "host-manager-switch";
        runtimeInputs = with pkgs; [nvd];
        text = ''
          oldGenerationPath="''$(readlink --canonicalize ${config.system.profile})"

          darwin-rebuild switch --flake "${repositoryDirectory}#${hostName}" "''$@"

          newGenerationPath="''$(readlink --canonicalize ${config.system.profile})"
          nvd diff "''$oldGenerationPath" "''$newGenerationPath"
        '';
      })
      (pkgs.writeShellApplication {
        name = "host-manager-upgrade";
        text = ''
          oldGenerationPath="''$(readlink --canonicalize ${config.system.profile})"

          darwin-rebuild switch --flake "${repositoryDirectory}#${hostName}" ${updateFlags.darwin} "''$@"

          newGenerationPath="''$(readlink --canonicalize ${config.system.profile})"
          nvd diff "''$oldGenerationPath" "''$newGenerationPath"
        '';
      })
    ];
  in
    {
      nix.useDaemon = true;

      users.users.${username} = {
        home = homeDirectory;
        inherit packages;
      };
    }
