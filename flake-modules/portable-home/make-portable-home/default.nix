{
  isGui,
  isMinimal,
  pkgs,
  self,
  modules ? [],
  overlays ? [],
  name ? "shell",
}: let
  inherit (pkgs) lib;
  inherit (lib.lists) optionals;
  inherit (pkgs.stdenv) isLinux;

  fish =
    if isMinimal
    then
      (pkgs.fish.override {
        usePython = false;
      })
    else pkgs.fish;

  # "C.UTF-8/UTF-8" is the locale that perl said wasn't supported so I added it here.
  # "en_US.UTF-8/UTF-8" is the default locale so I'm keeping it just in case.
  locales =
    if isMinimal
    then
      (pkgs.glibcLocales.override {
        allLocales = false;
        locales = ["en_US.UTF-8/UTF-8" "C.UTF-8/UTF-8"];
      })
    else pkgs.glibcLocales;

  makeEmptyPackage = packageName: pkgs.runCommand packageName {} ''mkdir -p $out/bin'';

  allModules =
    modules
    ++ optionals isMinimal [
      ({lib, ...}: {
        xdg = {
          dataFile = {
            "nvim/site/parser" = lib.mkForce {
              source = makeEmptyPackage "parsers";
            };
          };
        };
        home = {
          # remove moreutils dependency
          activation.batSetup = lib.mkForce (lib.hm.dag.entryAfter ["linkGeneration"] "");
        };
      })
    ];

  allOverlays =
    overlays
    ++ optionals isMinimal [
      (_final: prev: {
        moreutils = makeEmptyPackage "moreutils";
        ast-grep = makeEmptyPackage "ast-grep";
        timg = makeEmptyPackage "timg";
        ripgrep-all = makeEmptyPackage "ripgrep-all";
        lesspipe = makeEmptyPackage "lesspipe";
        wordnet = makeEmptyPackage "wordnet";
        diffoscope = makeEmptyPackage "diffoscope";
        myPython = makeEmptyPackage "myPython";
        gitMinimal = makeEmptyPackage "gitMinimal";

        fish = prev.fish.override {
          usePython = false;
        };
      })
    ];

  portableHome = let
    bashPath = "${pkgs.bash}/bin/bash";
    activationPackage = import ./home-manager-package.nix {
      inherit pkgs self isGui;
      modules = allModules;
      overlays = allOverlays;
    };
    localeArchive =
      if isLinux
      then "export LOCALE_ARCHIVE=${lib.escapeShellArg "${locales}/lib/locale/locale-archive"}"
      else "";
    bootstrap = pkgs.resholve.mkDerivation {
      pname = "bootstrap";
      version = "0.0.1";
      src = self;
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        install -D flake-modules/portable-home/make-portable-home/bootstrap.bash $out/bin/bootstrap
      '';
      solutions = {
        default = {
          scripts = ["bin/bootstrap"];
          interpreter = "${pkgs.bash}/bin/bash";
          inputs = with pkgs; [
            coreutils-full
            fish
            which
          ];
          execer = [
            "cannot:${pkgs.coreutils-full}/bin/mktemp"
            "cannot:${pkgs.coreutils-full}/bin/mkdir"
            "cannot:${pkgs.coreutils-full}/bin/basename"
            "cannot:${pkgs.coreutils-full}/bin/ln"
            "cannot:${pkgs.coreutils-full}/bin/chmod"
            "cannot:${pkgs.coreutils-full}/bin/cp"
          ];
          keep = {
            "$SHELL" = true;
          };
        };
      };
    };
  in
    (
      pkgs.writeScriptBin
      name
      ''        #!${bashPath}
                BASH_PATH=${bashPath}
                ACTIVATION_PACKAGE=${lib.escapeShellArg "${activationPackage}"}
                ${localeArchive}
                source ${bootstrap}/bin/bootstrap
      ''
    )
    // {meta.mainProgram = name;};
in
  portableHome
