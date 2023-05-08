{ config, lib, specialArgs, pkgs, ... }:
  let
    inherit (specialArgs) hostName homeDirectory username repositoryDirectory;
    repositoryAbsolutePath = "${homeDirectory}/${repositoryDirectory}";
    # Scripts for switching generations and upgrading flake inputs.
    packages = [
      (pkgs.writeShellApplication {
        name = "host-manager-switch";
        runtimeInputs = with pkgs; [nvd];
        text = ''
          # Add missing entries in sub-flake lock files so the top-level flake pulls them in when I do
          # `--update-input` below.
          nix flake lock '${repositoryAbsolutePath}/home-manager/overlay'

          oldGenerationPath="''$(readlink --canonicalize ${config.system.profile})"

          # I need `--update-input my-overlay` for the following reasons:
          #   - Without it, I get an error when trying to build home-manager on any machine where
          # `my-overlay` has not been built before.
          # More on this issue here: https://github.com/NixOS/nix/issues/3978#issuecomment-952418478
          # Nix team is working on a fix:
          # Where they said that: https://github.com/NixOS/nix/issues/3978#issuecomment-1510964326
          # The fix: https://github.com/NixOS/nix/pull/6530
          #   - Without it, when I run `home-manager switch`, I won't necessarily have the latest version of
          # `my-overlay`. This happens because when I first ran `home-manager switch` with `my-overlay` as an input,
          # the current version of `my-overlay` was stored in the flake.lock. So when I ran it again it continued
          # to use the version in the flake.lock, despite the changes I made locally. To make sure I always have
          # the latest version of `my-overlay` I have to use `--update-input my-overlay` before running
          # `home-manager switch`. There's an issue open to improve on this workflow though:
          # issue: https://github.com/NixOS/nix/issues/6352
          darwin-rebuild switch --flake "${repositoryAbsolutePath}#${hostName}" --update-input my-overlay "''$@"

          newGenerationPath="''$(readlink --canonicalize ${config.system.profile})"

          nvd diff "''$oldGenerationPath" "''$newGenerationPath"
        '';
      })
      (pkgs.writeShellApplication {
        name = "host-manager-upgrade";
        text = ''
          # Update inputs in sub-flakes so the top-level flake pulls them in.
          nix flake update '${repositoryAbsolutePath}/home-manager/overlay'

          darwin-rebuild switch --flake "${repositoryAbsolutePath}#${hostName}" --recreate-lock-file "''$@"
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
