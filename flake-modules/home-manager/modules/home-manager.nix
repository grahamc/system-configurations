{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (specialArgs) hostName username homeDirectory isHomeManagerRunningAsASubmodule updateFlags;
    inherit (lib.attrsets) optionalAttrs;
  in
    lib.mkMerge [
      {
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
      }
      (optionalAttrs (!isHomeManagerRunningAsASubmodule) {
        # Home Manager needs a bit of information about you and the
        # paths it should manage.
        home.username = username;
        home.homeDirectory = homeDirectory;

        # Scripts for switching generations and upgrading flake inputs.
        home.file = {
          ".local/bin/host-manager-switch" = {
            text = ''
              #!${pkgs.bash}/bin/bash
              home-manager switch --flake "${config.repository.directory}#${hostName}" "''$@"
            '';
            executable = true;
          };
          ".local/bin/host-manager-upgrade" = {
            text = ''
              #!${pkgs.bash}/bin/bash
              home-manager switch --flake "${config.repository.directory}#${hostName}" ${updateFlags.home} "''$@"
            '';
            executable = true;
          };
        };

        # Show me what changed everytime I switch generations e.g. version updates or added/removed files.
        home.activation = {
          printChanges = lib.hm.dag.entryAnywhere ''
            ${pkgs.nvd}/bin/nvd diff $oldGenPath $newGenPath
          '';
        };

        # host-manager-switch may not be defined by home-manager, it could be the system manager like nix-darwin.
        repository.git.onChange = [
          {
            # This should be the first check since other checks might depend on new files
            # being linked, or removed files being unlinked, in order to work. For example, if a new
            # bat theme is added, the theme needs to be linked before we can rebuild the bat cache.
            priority = 100;
            patterns = {
              added = ["*"];
              deleted = ["*"];
            };
            action = ''
              host-manager-switch
            '';
          }
        ];
      })
    ]
