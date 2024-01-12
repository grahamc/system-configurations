{
  pkgs,
  self,
  minimalFish,
}: let
  inherit (pkgs) lib system;
  inherit (lib.attrsets) optionalAttrs;
  inherit (pkgs.stdenv) isLinux;
  hostName = "guest-host";
  makeEmptyPackage = packageName: pkgs.runCommand packageName {} ''mkdir -p $out/bin'';

  minimalOverlay = _final: prev:
    {
      fish = minimalFish;
      comma = makeEmptyPackage "stub-comma";
      coreutils-full = prev.coreutils;
      gitMinimal = makeEmptyPackage "stub-git";

      vimPlugins =
        prev.vimPlugins
        // {
          markdown-preview-nvim = makeEmptyPackage "markdown-preview-nvim";
        };

      # `atuin uuid` kept calling itself so I'm removing it
      atuin = makeEmptyPackage "stub-atuin";
    }
    // optionalAttrs isLinux {
      tmux = prev.tmux.override {
        withSystemd = false;
      };
    };

  shellModule = _: {
    # I want a self contained executable so I can't have symlinks that point outside the Nix store.
    repository.symlink.makeCopiesInstead = true;

    programs.nix-index = {
      enable = false;
      symlinkToCacheHome = false;
    };

    programs.home-manager.enable = lib.mkForce false;

    # This removes the dependency on `sd-switch`.
    systemd.user.startServices = lib.mkForce "suggest";

    # These variables contain the path to the locale archive in pkgs.glibcLocales.
    # There is no option to prevent Home Manager from making these environment variables and overriding
    # glibcLocales in an overlay would cause too many rebuild so instead I overwrite the environment
    # variables. Now, glibcLocales won't be a dependency.
    home.sessionVariables = optionalAttrs isLinux (lib.mkForce {
      LOCALE_ARCHIVE_2_27 = "";
      LOCALE_ARCHIVE_2_11 = "";
    });

    home.file.".hammerspoon/Spoons/EmmyLua.spoon" = lib.mkForce {
      source = makeEmptyPackage "stub-spoon";
      recursive = false;
    };

    xdg = {
      mime.enable = lib.mkForce false;

      dataFile = {
        "fzf/fzf-history.txt".source = pkgs.writeText "fzf-history.txt" "";

        # I do this to override the original link to the treesitter parsers.
        "nvim/site/parser".source = lib.mkForce (makeEmptyPackage "stub-parser");

        # `atuin uuid` kept calling itself so I'm removing the script
        "fish/vendor_completions.d/atuin.fish".source = lib.mkForce (pkgs.writeText "atuin-complete.fish" "");
      };

      # `atuin uuid` kept calling itself so I'm removing the script
      configFile."fish/conf.d/atuin.fish".source = lib.mkForce (pkgs.writeText "atuin-config.fish" "");
    };
  };

  homeManagerOutput = self.lib.home.makeFlakeOutput system {
    inherit hostName;
    isGui = false;
    overlays = [minimalOverlay];

    # I want to remove the systemd dependency, but there is no option for that. Instead, I set the user
    # to root since Home Manager won't include systemd if the user is root.
    # see: https://github.com/nix-community/home-manager/blob/master/modules/systemd.nix
    username = "root";

    modules = [
      "${self.lib.home.moduleBaseDirectory}/profile/system-administration.nix"
      shellModule
    ];
  };
in
  homeManagerOutput.legacyPackages.homeConfigurations.${hostName}.activationPackage
