# This output lets me run my shell environment, both programs and their config files, completely from the nix store.
# Useful for headless servers or containers.
{ inputs, self, ... }:
  {
    perSystem = {lib, system, pkgs, ...}:
      let
        inherit (lib.attrsets) optionalAttrs;
        shellOutput =
          let
            hostName = "no-host";
            minimalFish = pkgs.fish.override {
              usePython = false;
            };
            minimalOverlay = final: prev: {
              fish = minimalFish;
              tmux = prev.tmux.override {
                withSystemd = false;
              };
              fzf = prev.fzf.override { perl = prev.perl534; };
              git = pkgs.gitMinimal;
            };
            homeManagerOutput = self.lib.makeFlakeOutput system {
              inherit hostName;
              # To remove the systemd dependency
              username = "root";
              modules = with self.lib.modules; [
                profile.system-administration
                ({config, ...}: {
                  # I want a self contained executable so I can't have symlinks that point outside the Nix store.
                  config.repository.symlink.makeCopiesInstead = true;
                  config.programs.fish.enable = lib.mkForce false;
                  config.programs.fish.package = minimalFish;
                  config.xdg.dataFile."nvim/site/parser".source = lib.mkForce
                    (pkgs.writeShellApplication {name = "fake"; text = "";});
                  config.programs.nix-index = {
                    enable = false;
                    symlinkToCacheHome = false;
                  };
                  config.home.activation.printChanges = lib.mkForce "";
                  config.programs.home-manager.enable = lib.mkForce false;
                  config.systemd.user.startServices = lib.mkForce "suggest";
                })
              ];
              isGui = false;
              overlays = [minimalOverlay];
            };
            inherit (homeManagerOutput.legacyPackages.homeConfigurations.${hostName}) activationPackage;
            # I don't want the programs that this script depends on to be in the $PATH since they are not
            # necessarily part of my Home Manager configuration so I'll set them to variables instead.
            coreutilsBinaryPath = "${pkgs.coreutils}/bin";
            mktemp = "${coreutilsBinaryPath}/mktemp";
            copy = "${coreutilsBinaryPath}/cp";
            chmod = "${coreutilsBinaryPath}/chmod";
            basename = "${coreutilsBinaryPath}/basename";
            which = "${pkgs.which}/bin/which";
            foreignEnvFunctionPath = "${pkgs.fishPlugins.foreign-env}/share/fish/vendor_functions.d";
            fish = "${minimalFish}/bin/fish";
            shellBootstrapScriptName = "shell";
            shellBootstrapScript = import ./shell-bootstrap-script.nix
              {
                inherit
                  activationPackage
                  mktemp
                  copy
                  chmod
                  fish
                  coreutilsBinaryPath
                  basename
                  which
                  foreignEnvFunctionPath
                  ;
              };
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
