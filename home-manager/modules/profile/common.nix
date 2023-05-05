{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (specialArgs) hostName nix-index-database username homeDirectory;
    repoRelativeToHome = ".dotfiles";
    repo = "${config.home.homeDirectory}/${repoRelativeToHome}";
  in
    {
      imports = [
        ../login-shell.nix
        ../fish.nix
        ../nix.nix
        ../neovim.nix
        ../general.nix
        nix-index-database.hmModules.nix-index
        ../utility/symlink.nix
        ../utility/vim-plug.nix
        ../utility/git-repository/git-repository.nix
      ];

      symlink.repositoryDirectory = repo;
      gitRepository.repositoryPath = repoRelativeToHome;

      gitRepository.onChangeHandlers = [
        {
          # This should be the first check since other checks might depend on new files
          # being linked, or removed files being unlinked, in order to work. For example, if a new
          # bat theme is added, the theme needs to be linked before we can rebuild the bat cache.
          priority = 100;
          patterns = {
            added = ["*"];
            deleted = ["*"];
            modified = ["\\.nix$" "flake\\.lock"];
          };
          action = ''
            home-manager-switch
          '';
        }
      ];

      # Home Manager needs a bit of information about you and the
      # paths it should manage.
      home.username = username;
      home.homeDirectory = homeDirectory;

      # The `man` in nixpkgs is only intended to be used for NixOS, it doesn't work properly on other OS's so I'm disabling
      # it. Since I'm not using the nixpkgs man, I have any packages I install their man outputs so my
      # system's `man` can find them.
      programs.man.enable = false;
      home.extraOutputsToInstall = [ "man" ];

      # This value determines the Home Manager release that your
      # configuration is compatible with. This helps avoid breakage
      # when a new Home Manager release introduces backwards
      # incompatible changes.
      #
      # You can update Home Manager without changing this value. See
      # the Home Manager release notes for a list of state version
      # changes in each release.
      home.stateVersion = "22.11";

      # Let Home Manager install and manage itself.
      programs.home-manager.enable = true;

      home.file = {
        ".local/bin/home-manager-switch" = {
          text = ''
            #!${pkgs.bash}/bin/bash

            # Add missing entries in sub-flake lock files so the top-level flake pulls them in when I do
            # `--update-input` below.
            nix flake lock '${repo}/home-manager/overlay'
            nix flake lock '${repo}/smart-plug'

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
            home-manager switch --flake "${repo}#${hostName}" --update-input my-overlay --update-input smart-plug
          '';
          executable = true;
        };
        ".local/bin/home-manager-upgrade" = {
          text = ''
            #!${pkgs.bash}/bin/bash

            # Update inputs in sub-flakes so the top-level flake pulls them in.
            nix flake update '${repo}/home-manager/overlay'

            home-manager switch --flake "${repo}#${hostName}" --recreate-lock-file
          '';
          executable = true;
        };
      };

      home.activation.printChanges = lib.hm.dag.entryAnywhere ''
        ${pkgs.nvd}/bin/nvd diff $oldGenPath $newGenPath
      '';

      # When switching generations, stop obsolete services and start ones that are wanted by active units.
      systemd.user.startServices = "sd-switch";
    }
