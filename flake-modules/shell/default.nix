# This output lets me run my shell environment, both programs and their config files, completely from the nix store.
# Useful for headless servers or containers.
#
# I also bundle this output into an executable (check the GitHub actions for this repository to see how) so there
# is some configuration added here to try and make the resulting executable smaller. For example, removing
# dependencies that are particularly large like systemd.
{ inputs, self, ... }:
  {
    perSystem = {lib, system, pkgs, ...}:
      let
        inherit (lib.attrsets) optionalAttrs;
        inherit (pkgs.stdenv) isLinux;
        shellOutput =
          let
            hostName = "guest-host";
            # When I can't remove a package, I replace it with this.
            emptyPackage = pkgs.writeShellApplication
              {
                name = "fake";
                text = "echo 'This command is not supported in portable mode.'";
              };
            minimalFish = pkgs.fish.override {
              usePython = false;
            };
            # "C.UTF-8/UTF-8" is the locacle the perl said wasn't supported so I added it here.
            # "en_US.UTF-8/UTF-8" was the default locacle so I'm keeping it just in case.
            minimalLocales = pkgs.glibcLocales.override { allLocales = false;  locales = ["en_US.UTF-8/UTF-8" "C.UTF-8/UTF-8"];};
            minimalOverlay = final: prev: {
              fish = minimalFish;
              tmux = prev.tmux.override {
                withSystemd = false;
              };
              comma = emptyPackage;
              coreutils-full = prev.coreutils;
              gitMinimal = emptyPackage;
            } // optionalAttrs isLinux {
              fzf = prev.fzf.override {
                glibcLocales = minimalLocales;
              };
              open = emptyPackage;
            };
            shellModule = {config, ...}:
              {
                # I want a self contained executable so I can't have symlinks that point outside the Nix store.
                config.repository.symlink.makeCopiesInstead = true;
                # I do this to override the original link to the treesitter parsers.
                config.xdg.dataFile."nvim/site/parser".source = lib.mkForce emptyPackage;
                config.programs.nix-index = {
                  enable = false;
                  symlinkToCacheHome = false;
                };
                # I do this to override the original 'printChanges' activation script so I can remove the dependency
                # on `nvd`.
                config.home.activation.printChanges = lib.mkForce "";
                config.programs.home-manager.enable = lib.mkForce false;
                # This removes the dependency on `sd-switch`.
                config.systemd.user.startServices = lib.mkForce "suggest";
                # These variables contain the path to the locale archive in pkgs.glibcLocales.
                # There is no option to prevent Home Manager from making these environment variables and overriding
                # glibcLocales in an overlay would cause too many rebuild so instead I overwrite the environment
                # variables. Now, glibcLocales won't be a dependency.
                config.home.sessionVariables = optionalAttrs isLinux (lib.mkForce {
                  LOCALE_ARCHIVE_2_27 = "";
                  LOCALE_ARCHIVE_2_11 = "";
                });
                config.xdg.mime.enable = lib.mkForce false;
              };
            homeManagerOutput = self.lib.home.makeFlakeOutput system {
              inherit hostName;
              # I want to remove the systemd dependency, but there is no option for that. Instead, I set the user
              # to root since Home Manager won't include systemd if the user is root.
              # see: https://github.com/nix-community/home-manager/blob/master/modules/systemd.nix
              username = "root";
              modules = [
                "${self.lib.home.moduleBaseDirectory}/profile/system-administration.nix"
                shellModule
              ];
              isGui = false;
              overlays = [minimalOverlay];
            };
            shellBootstrapScriptName = "shell";
            # Normally, to make a shell script I would use the function `nixpkgs.writeShellApplication` and specify
            # its dependencies through the attribute `runtimeInputs`. Then those dependencies would be added to the
            # $PATH before the script executes. In this case, I don't want the programs that the script depends on to
            # be in the $PATH because I don't want them on the $PATH of the shell that gets launched at the end of the
            # script. Instead, I'll supply the dependencies through the variables listed below.
            shellBootstrapScriptDependencies = rec {
              inherit (homeManagerOutput.legacyPackages.homeConfigurations.${hostName}) activationPackage;
              coreutilsBinaryPath = "${pkgs.coreutils}/bin";
              mktemp = "${coreutilsBinaryPath}/mktemp";
              copy = "${coreutilsBinaryPath}/cp";
              chmod = "${coreutilsBinaryPath}/chmod";
              basename = "${coreutilsBinaryPath}/basename";
              fish = "${minimalFish}/bin/fish";
              which = "${pkgs.which}/bin/which";
              foreignEnvFunctionPath = "${pkgs.fishPlugins.foreign-env}/share/fish/vendor_functions.d";
            } // optionalAttrs isLinux {
              localeArchive = "${minimalLocales}/lib/locale/locale-archive";
            };
            shellBootstrapScript = import ./shell-bootstrap-script.nix shellBootstrapScriptDependencies;
            shellBootstrap = pkgs.writeScriptBin shellBootstrapScriptName shellBootstrapScript;
          in
            {
              apps.default = {
                type = "app";
                program = "${shellBootstrap}/bin/${shellBootstrapScriptName}";
              };
              packages.shell = shellBootstrap;
            };
        supportedSystems = with inputs.flake-utils.lib.system; [ x86_64-linux x86_64-darwin ];
        isSupportedSystem = builtins.elem system supportedSystems;
      in
        optionalAttrs isSupportedSystem shellOutput;
  }
