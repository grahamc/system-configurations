{
  isGui,
  pkgs,
  self,
}: let
  inherit (pkgs) lib;
  inherit (lib.attrsets) optionalAttrs;
  inherit (pkgs.stdenv) isLinux;
  minimalFish = pkgs.fish.override {
    usePython = false;
  };

  # "C.UTF-8/UTF-8" is the locacle the perl said wasn't supported so I added it here.
  # "en_US.UTF-8/UTF-8" was the default locacle so I'm keeping it just in case.
  minimalLocales = pkgs.glibcLocales.override {
    allLocales = false;
    locales = ["en_US.UTF-8/UTF-8" "C.UTF-8/UTF-8"];
  };

  shellBootstrapScriptName = "shell";

  # Normally, to make a shell script I would use the function `nixpkgs.writeShellApplication`
  # and specify its dependencies through the attribute `runtimeInputs`. Then those
  # dependencies would be added to the $PATH before the script executes. In this case, I don't
  # want the programs that the script depends on to be in the $PATH because I don't want them
  # on the $PATH of the shell that gets launched at the end of the script. Instead, I'll
  # supply the dependencies through the variables listed below.
  coreutilsBinaryPath = "${pkgs.coreutils}/bin";
  shellBootstrapScriptDependencies =
    {
      activationPackage = import ./home-manager-package.nix {inherit pkgs self minimalFish isGui;};
      mktemp = "${coreutilsBinaryPath}/mktemp";
      copy = "${coreutilsBinaryPath}/cp";
      chmod = "${coreutilsBinaryPath}/chmod";
      basename = "${coreutilsBinaryPath}/basename";
      fish = "${minimalFish}/bin/fish";
      which = "${pkgs.which}/bin/which";
    }
    // optionalAttrs isLinux {
      localeArchive = "${minimalLocales}/lib/locale/locale-archive";
    };
  shellBootstrapScript = import ./shell-bootstrap-script.nix shellBootstrapScriptDependencies;

  shellBootstrap = pkgs.writeScriptBin shellBootstrapScriptName shellBootstrapScript;
in
  shellBootstrap
