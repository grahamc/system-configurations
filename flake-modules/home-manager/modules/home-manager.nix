{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (specialArgs) hostName username homeDirectory isHomeManagerRunningAsASubmodule updateFlags;
    inherit (lib.attrsets) optionalAttrs;

    # Scripts for switching generations and upgrading flake inputs.
    host-manager-switch = pkgs.writeShellApplication
      {
        name = "host-manager-switch";
        text = ''
          home-manager switch --flake "${config.repository.directory}#${hostName}" "''$@"
        '';
      };
    host-manager-upgrade = pkgs.writeShellApplication
      {
        name = "host-manager-upgrade";
        text = ''
          home-manager switch --flake "${config.repository.directory}#${hostName}" ${updateFlags.home} "''$@"
        '';
      };
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
        home.stateVersion = "23.05";

        # Let Home Manager install and manage itself.
        programs.home-manager.enable = true;

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
      }
      # These are all things that don't need to be done when home manager is being run as a submodule inside of
      # another host manager, like nix-darwin. They don't need to be done because the outer host manager will do them.
      (optionalAttrs (!isHomeManagerRunningAsASubmodule) {
        # Home Manager needs a bit of information about you and the
        # paths it should manage.
        home.username = username;
        home.homeDirectory = homeDirectory;

        home.packages = [
          host-manager-switch
          host-manager-upgrade
        ];

        # Show me what changed everytime I switch generations e.g. version updates or added/removed files.
        home.activation = {
          printChanges = lib.hm.dag.entryAnywhere ''
            ${pkgs.nvd}/bin/nvd diff $oldGenPath $newGenPath
          '';
        };
      })
    ]
