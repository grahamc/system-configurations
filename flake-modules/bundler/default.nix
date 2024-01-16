{
  inputs,
  self,
  ...
}: {
  imports = [
    # I defined this in a separate file to avoid an infinite recursion. The function use in
    # option.nix that makes the bundler option return a set with the keys `config` and `option`.
    # The set returned here would also have a `config` key, for the perSystem. To combine the two,
    # I would use my helper function `self.lib.recursiveMerge`. It needs to be recursive since
    # they both share a config key. I get an infinite recursion because the output of the call to
    # self.lib.recursiveMerge would affect the value of self.
    ./option.nix
  ];

  perSystem = {
    lib,
    system,
    pkgs,
    ...
  }: let
    inherit (lib.attrsets) optionalAttrs;
    makeExecutable = {
      derivation,
      entrypoint,
      name,
    }: let
      nameWithArch = "${name}-${system}";
      goPkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [
          inputs.gomod2nix.overlays.default
        ];
      };
      gozip = goPkgs.buildGoApplication {
        pname = "gozip";
        version = "0.1";
        src = ./gozip;
        pwd = ./gozip;
        modules = ./gozip/gomod2nix.toml;
        # Adding these tags so the gozip executable is built statically.
        # More info: https://mt165.co.uk/blog/static-link-go
        tags = ["osusergo" "netgo"];
      };
    in
      pkgs.stdenv.mkDerivation {
        pname = nameWithArch;
        name = nameWithArch;
        src = self;
        buildInputs = [gozip];
        installPhase = ''
          mkdir deps
          cp --recursive $(cat ${pkgs.writeReferencesToFile derivation}) ./deps/
          chmod -R 777 ./deps
          cd ./flake-modules/bundler/gozip
          cp --dereference "$(${pkgs.which}/bin/which gozip)" $out
          cd ../../../deps
          cp ${entrypoint} entrypoint
          chmod 777 entrypoint
          chmod +w $out
          gozip -internalCreate $out ./*
        '';
      };

    defaultBundler = let
      basename = p: pkgs.lib.lists.last (builtins.split "/" p);

      program = drv: let
        # Use same auto-detect that <https://github.com/NixOS/bundlers>
        # uses. This isn't 100% accurate and might pick the wrong name
        # (e.g. nixpkgs#mesa-demos), so we do an additional check to
        # make sure the target exists
        main =
          if drv ? meta && drv.meta ? mainProgram
          then drv.meta.mainProgram
          else (builtins.parseDrvName (builtins.unsafeDiscardStringContext drv.name)).name;
        mainPath = "${drv}/bin/${main}";

        # builtins.pathExists mainPath doesn't work consistently (e.g.
        # for symlinks), but this does
        mainPathExists = builtins.hasAttr main (builtins.readDir "${drv}/bin");
      in
        assert pkgs.lib.assertMsg mainPathExists "main program ${mainPath} does not exist"; mainPath;

      handler = {
        app = drv:
          makeExecutable {
            derivation = drv.program;
            entrypoint = drv.program;
            name = basename drv.program;
          };
        derivation = drv:
          makeExecutable {
            derivation = drv;
            entrypoint = program drv;
            inherit (drv) name;
          };
      };
      known-types = builtins.concatStringsSep ", " (builtins.attrNames handler);
    in
      drv:
        assert pkgs.lib.assertMsg (handler ? ${drv.type}) "don't know how to make a bundle for type '${drv.type}'; only know ${known-types}";
          handler.${drv.type} drv;

    bundlerOutput = {
      bundlers.default = defaultBundler;
    };

    supportedSystems = with inputs.flake-utils.lib.system; [x86_64-linux x86_64-darwin];
    isSupportedSystem = builtins.elem system supportedSystems;
  in
    optionalAttrs isSupportedSystem bundlerOutput;
}
