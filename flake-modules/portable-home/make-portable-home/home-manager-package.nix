{
  pkgs,
  self,
  isGui,
  modules ? [],
  overlays ? [],
}: let
  inherit (pkgs) system;
  inherit (pkgs.stdenv) isLinux;
  hostName = "guest-host";
  makeEmptyPackage = packageName: pkgs.runCommand packageName {} ''mkdir -p $out/bin'';

  portableOverlay = _final: _prev: {
    comma = makeEmptyPackage "stub-comma";
  };

  portableModule = {lib, ...}: {
    # I want a self contained executable so I can't have symlinks that point outside the Nix store.
    repository.symlink.makeCopiesInstead = true;

    programs.nix-index = {
      enable = false;
      symlinkToCacheHome = false;
    };

    programs.home-manager.enable = lib.mkForce false;

    # This removes the dependency on `sd-switch`.
    systemd.user.startServices = lib.mkForce "suggest";
    home = {
      # These variables contain the path to the locale archive in pkgs.glibcLocales.
      # There is no option to prevent Home Manager from making these environment variables and overriding
      # glibcLocales in an overlay would cause too many rebuild so instead I overwrite the environment
      # variables. Now, glibcLocales won't be a dependency.
      sessionVariables = lib.attrsets.optionalAttrs isLinux (lib.mkForce {
        LOCALE_ARCHIVE_2_27 = "";
        LOCALE_ARCHIVE_2_11 = "";
      });

      file.".hammerspoon/Spoons/EmmyLua.spoon" = lib.mkForce {
        source = makeEmptyPackage "stub-spoon";
        recursive = false;
      };

      packages = lib.lists.optionals isGui [pkgs.wezterm];
    };

    xdg = {
      mime.enable = lib.mkForce false;

      dataFile = {
        "fzf/fzf-history.txt".source = pkgs.writeText "fzf-history.txt" "";
      };
    };

    # to remove the flake registry
    nix.enable = false;
  };

  homeManagerOutput = self.lib.home.makeFlakeOutput system {
    inherit hostName isGui;
    overlays = [portableOverlay] ++ overlays;

    # I want to remove the systemd dependency, but there is no option for that. Instead, I set the user
    # to root since Home Manager won't include systemd if the user is root.
    # see: https://github.com/nix-community/home-manager/blob/master/modules/systemd.nix
    username = "root";

    modules =
      [
        "${self.lib.home.moduleBaseDirectory}/profile/system-administration.nix"
        portableModule
      ]
      ++ modules;
  };
in
  homeManagerOutput.legacyPackages.homeConfigurations.${hostName}.activationPackage
