# This output lets me run my shell environment, both programs and their config files, completely from the nix store.
# Useful for headless servers or containers.
#
# I also bundle this output into an executable (check the GitHub actions for this repository to see how) so there
# is some configuration added here to try and make the resulting executable smaller. For example, removing
# dependencies that are particularly large like systemd.
{ inputs, self, ... }:
  {
    perSystem = {lib, system, pkgs, self', ...}:
      let
        inherit (lib.attrsets) optionalAttrs;
        shellOutput =
          let
            makeRewriteExe =
              let
                appPackage = self'.packages.shell;
                exe = pkgs.stdenv.mkDerivation rec {
                  pname = "rewriteExe";
                  name = pname;
                  src = self;
                  installPhase = ''
                    mkdir deps
                    mkdir preDeps
                    cp --recursive $(cat ${pkgs.writeReferencesToFile appPackage}) ./deps/
                    chmod -R 777 ./deps
                    cd ./flake-modules/rootless-bundler/gozip
                    GOBIN="$PWD" ${pkgs.go}/bin/go install ./cmd/gozip/main.go
                    cp main $out
                    cd ../../../deps
                    cp ${self'.apps.default.program} entrypoint
                    chmod 777 entrypoint
                    ../flake-modules/rootless-bundler/gozip/main -c $out ./*
                  '';
                };
              in
                exe;
          in
            {
              packages.rewrite = makeRewriteExe;
            };
        supportedSystems = with inputs.flake-utils.lib.system; [ x86_64-linux x86_64-darwin ];
        isSupportedSystem = builtins.elem system supportedSystems;
      in
        optionalAttrs isSupportedSystem shellOutput;
  }

