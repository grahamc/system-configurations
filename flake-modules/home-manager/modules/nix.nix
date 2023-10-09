{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (specialArgs) flakeInputs;
    nix-daemon-reload = pkgs.writeShellApplication
      {
        name = "nix-daemon-reload";
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
        flakeInputs.nix-index-database.hmModules.nix-index
      ];

      # Don't make a command_not_found handler
      programs.nix-index.enableFishIntegration = false;

      repository.symlink.xdg.configFile = {
        "nix/nix.conf".source = "nix/nix.conf";
        "nix/repl-startup.nix".source = "nix/repl-startup.nix";
        "fish/conf.d/nix.fish".source = "nix/nix.fish";
      };

      xdg.configFile = {
        "fish/conf.d/any-nix-shell.fish".source = ''${
          pkgs.runCommand "any-nix-shell-config.fish" {} "${pkgs.any-nix-shell}/bin/any-nix-shell fish > $out"
        }'';
      };

      home.packages = with pkgs; [
        any-nix-shell
        nix-tree
        comma
        nix-daemon-reload
      ];

      repository.symlink.xdg.executable = {
        "nix".source = "nix/nix-repl-wrapper.fish";
        "nix-gcroots".source = "nix/nix-gcroots.fish";
        "nix-info".source = "nix/nix-info.fish";
      };
    }
