{ pkgs, specialArgs, ... }:
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
        "fish/conf.d/any-nix-shell.fish".source =
          let
            generateAnyNixShellFishConfig = pkgs.writeShellApplication {
              name = "generate";
              # any-nix-shell has to be on the $PATH when I generate the config file since the config generator will use
              # `which` to embed the path to `.any-nix-shell-wrapper`.
              runtimeInputs = with pkgs; [any-nix-shell which];
              text = ''
                any-nix-shell fish
              '';
            };
            anyNixShellFishConfig = pkgs.runCommand
              "any-nix-shell-config.fish"
              {}
              ''${generateAnyNixShellFishConfig}/bin/generate > $out'';
          in
            ''${anyNixShellFishConfig}'';
      };

      home.packages = with pkgs; [
        any-nix-shell
        nix-tree
        nix-melt
        comma
        nix-daemon-reload
        nil
      ];

      repository.symlink.xdg.executable = {
        "nix".source = "nix/nix-repl-wrapper.fish";
        "nix-gcroots".source = "nix/nix-gcroots.fish";
        "nix-info".source = "nix/nix-info.fish";
        "nix-upgrade-profiles".source = "nix/nix-upgrade-profiles.fish";
        "pynix".source = "nix/pynix.bash";
      };

      # Use the nixpkgs in this flake in the system flake registry. By default, it pulls the
      # latest version of nixokgs-unstable.
      nix.registry = {
        nixpkgs.flake = flakeInputs.nixpkgs; 
      };

      repository.git.onChange = [
        {
          patterns = {
            modified = [''^flake\.lock$''];
          };
          action = ''
            # If the lock file changed then it's possible that some of the flakes in my registry
            # have changed so I'll upgrade the packages installed from those registries.
            nix-upgrade-profiles
          '';
        }
      ];
    }
