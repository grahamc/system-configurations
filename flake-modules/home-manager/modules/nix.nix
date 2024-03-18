{
  pkgs,
  specialArgs,
  lib,
  ...
}: let
  inherit (specialArgs) flakeInputs;
  inherit (lib.attrsets) optionalAttrs;
  inherit (pkgs.stdenv) isDarwin;
  nix-daemon-reload =
    pkgs.writeShellApplication
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
in {
  imports = [
    flakeInputs.nix-index-database.hmModules.nix-index
  ];

  # Don't make a command_not_found handler
  programs.nix-index.enableFishIntegration = false;

  xdg.configFile = {
    "fish/conf.d/any-nix-shell.fish".source = let
      generateAnyNixShellFishConfig = pkgs.writeShellApplication {
        name = "generate";
        # any-nix-shell has to be on the $PATH when I generate the config file since the config generator will use
        # `which` to embed the path to `.any-nix-shell-wrapper`.
        runtimeInputs = with pkgs; [any-nix-shell which];
        text = ''
          any-nix-shell fish
        '';
      };
      anyNixShellFishConfig =
        pkgs.runCommand
        "any-nix-shell-config.fish"
        {}
        ''${generateAnyNixShellFishConfig}/bin/generate > $out'';
    in ''${anyNixShellFishConfig}'';
  };

  home.packages = with pkgs; [
    any-nix-shell
    nix-tree
    nix-melt
    comma
    nix-daemon-reload
    nix-output-monitor
  ];

  repository = {
    symlink.xdg = {
      executable = {
        "nix-gcroots".source = "nix/nix-gcroots.fish";
        "nix-info".source = "nix/nix-info.fish";
        "nix-upgrade-profiles".source = "nix/nix-upgrade-profiles.fish";
        "pynix".source = "nix/pynix.bash";
        "nix".source = "nix/nix-wrapper.fish";
      };

      configFile =
        {
          "nix/nix.conf".source = "nix/nix.conf";
          "nix/repl-startup.nix".source = "nix/repl-startup.nix";
          "fish/conf.d/zz-nix.fish".source = "nix/zz-nix.fish";
        }
        // optionalAttrs isDarwin {
          # TODO: On macOS, fish isn't reading the /usr/local/share/fish/vendor_conf.d confs for some
          # reason so I have to put this in a user directory.
          "fish/conf.d/zz-nix-fix.fish".source = "nix/nix-fix/zz-nix-fix.fish";
        };
    };

    git.onChange = let
      nixFixPattern = "nix-fish/";
    in [
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
      {
        patterns = {
          modified = [nixFixPattern];
          added = [nixFixPattern];
          deleted = [nixFixPattern];
        };

        action = ''
          if uname | grep -q Linux; then
            echo 'The Nix $PATH fix for fish shell has changed. To apply these changes re-run the install script `${specialArgs.flakeInputs.self}/dotfiles/nix/nix-fix/install-nix-fix.bash`. Press enter to continue'

            # To hide any keys the user may press before enter I disable echo. After prompting them, I re-enable it.
            stty_original="$(stty -g)"
            stty -echo
            # I don't care if read mangles backslashes since I'm not using the input anyway.
            # shellcheck disable=2162
            read _unused
            stty "$stty_original"
          fi
        '';
      }
    ];
  };

  # Use the nixpkgs in this flake in the system flake registry. By default, it pulls the
  # latest version of nixokgs-unstable.
  nix.registry = {
    nixpkgs.flake = flakeInputs.nixpkgs;
  };
}
