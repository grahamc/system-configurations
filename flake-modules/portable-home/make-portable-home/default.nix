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
  inherit (lib.attrsets) optionalAttrs;
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

  coreutilsBinaryPath = "${pkgs.coreutils-full}/bin";

  bootstrapScript = let
    # Normally, to make a shell script I would use the function
    # `nixpkgs.writeShellApplication` and specify its dependencies through
    # the attribute `runtimeInputs`. Then those dependencies would be added
    # to the $PATH before the script executes. In this case, I don't want the
    # programs that the script depends on to be in the $PATH because I don't
    # want them on the $PATH of the shell that gets launched at the end of the
    # script. Instead, I'll supply the dependencies through the variables listed
    # below.
    shellBootstrapScriptDependencies =
      {
        activationPackage = import ./home-manager-package.nix {
          inherit pkgs self isGui;
          modules = allModules;
          overlays = allOverlays;
        };
        mktemp = "${coreutilsBinaryPath}/mktemp";
        mkdir = "${coreutilsBinaryPath}/mkdir";
        ln = "${coreutilsBinaryPath}/ln";
        copy = "${coreutilsBinaryPath}/cp";
        chmod = "${coreutilsBinaryPath}/chmod";
        basename = "${coreutilsBinaryPath}/basename";
        fish = "${fish}/bin/fish";
        sh = "${pkgs.yash}/bin/yash";
        which = "${pkgs.which}/bin/which";
      }
      // optionalAttrs isLinux {
        localeArchive = "${locales}/lib/locale/locale-archive";
      };
  in
    import ./make-bootstrap-script.nix shellBootstrapScriptDependencies;

  portableHome = pkgs.writeScriptBin name bootstrapScript // {meta.mainProgram = name;};
in
  portableHome
