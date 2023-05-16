{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (lib.lists) optionals;
    inherit (pkgs.stdenv) isLinux;
    inherit (specialArgs) nix-index-database;
    nix-daemon-reload = pkgs.writeShellApplication
      {
        name = "nix-daemon-reload";
        runtimeInputs = [pkgs.xdg-utils];
        text = ''
          if uname | grep -q Linux; then
            systemctl restart nix-daemon.service
          else
            sudo launchctl stop org.nixos.nix-daemon && sudo launchctl start org.nixos.nix-daemon
          fi
        '';
      };
  in
    {
      imports = [
        nix-index-database.hmModules.nix-index
      ];

      # Don't make a command_not_found handler
      programs.nix-index.enableFishIntegration = false;

      repository.symlink.xdg.configFile = {
        "nix/nix.conf".source = "nix/nix.conf";
        "nix/repl-startup.nix".source = "nix/repl-startup.nix";
        # I prefixed the name of this file with 'my-' because otherwise it would have the same name as the configuration
        # file that comes with Nix. This is a problem because if fish sees two config files with the same basename, only
        # one gets loaded: https://fishshell.com/docs/current/language.html#configuration-files.
        "fish/conf.d/my-nix.fish".source = "nix/nix.fish";
      };

      home.packages = with pkgs; [
        any-nix-shell
        nix-tree
        comma
        nix-daemon-reload
        nix-info
        manix
      ];

      repository.symlink.home.file = {
        ".local/bin/nix".source = "nix/nix-repl-wrapper.fish";
      };
    }
