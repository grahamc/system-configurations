{lib, inputs, self, ... }:
  {
    imports = [
      # I defined this in a separate file to avoid an infinite recursion. The function use in option.nix that makes
      # the bundler option return a set with the keys `config` and `option`. The set returned here would also have
      # a `config` key, for the perSystem. To combine the two, I would use my helper function
      # `self.lib.recursiveMerge`. It needs to be recursive since they both share a config key. I get an infinite
      # recursion because the output of the call to self.lib.recursiveMerge would affect the value of self.
      ./option.nix
    ];

    perSystem = {lib, system, pkgs, self', ...}:
      let
        inherit (lib.attrsets) optionalAttrs;
        makeExecutable = {derivation, entrypoint, name}:
          let
            nameWithArch = "${name}-${system}";
          in
            pkgs.stdenv.mkDerivation {
              pname = nameWithArch;
              name = nameWithArch;
              src = self;
              installPhase = ''
                mkdir deps
                mkdir preDeps
                cp --recursive $(cat ${pkgs.writeReferencesToFile derivation}) ./deps/
                chmod -R 777 ./deps
                cd ./flake-modules/bundler/gozip
                # Go tries to access the home directory to make a cache, but we don't have one in this build
                # environment so put the cache in the current directory.
                mkdir gocache
                GOCACHE="$PWD/gocache" GOBIN="$PWD" ${pkgs.go}/bin/go install ./cmd/gozip/main.go
                cp main $out
                cd ../../../deps
                cp ${entrypoint} entrypoint
                chmod 777 entrypoint
                ../flake-modules/bundler/gozip/main -c $out ./*
              '';
            };

        defaultBundler =
          let
            basename = p: pkgs.lib.lists.last (builtins.split "/" p);

            program = drv:
              let
                # Use same auto-detect that <https://github.com/NixOS/bundlers>
                # uses. This isn't 100% accurate and might pick the wrong name
                # (e.g. nixpkgs#mesa-demos), so we do an additional check to
                # make sure the target exists
                main =
                  if drv?meta && drv.meta?mainProgram then drv.meta.mainProgram
                  else (builtins.parseDrvName (builtins.unsafeDiscardStringContext drv.name)).name;
                mainPath = "${drv}/bin/${main}";

                # builtins.pathExists mainPath doesn't work consistently (e.g.
                # for symlinks), but this does
                mainPathExists = builtins.hasAttr main (builtins.readDir "${drv}/bin");
              in
              assert pkgs.lib.assertMsg mainPathExists "main program ${mainPath} does not exist";
              mainPath;

            handler = {
              app = drv: makeExecutable {
                derivation = drv.program;
                entrypoint = drv.program;
                name = basename drv.program;
              };
              derivation = drv: makeExecutable {
                derivation = drv;
                entrypoint = program drv;
                name = drv.name;
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

        supportedSystems = with inputs.flake-utils.lib.system; [ x86_64-linux x86_64-darwin ];
        isSupportedSystem = builtins.elem system supportedSystems;
      in
        optionalAttrs isSupportedSystem bundlerOutput;
  }
    
