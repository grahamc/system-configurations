# These are packages that I need to set up my flake.
{inputs, ...}: {
  perSystem = {
    pkgs,
    lib,
    inputs',
    system,
    ...
  }: let
    inherit (lib.attrsets) optionalAttrs;
    inherit (pkgs.stdenv) isDarwin;

    # TODO: would be nice if firstaide started doing releases again
    firstaidePackage = pkgs.rustPlatform.buildRustPackage {
      pname = "firstaide";
      version = "master";
      src = inputs.firstaide;

      cargoLock = {
        lockFile = "${inputs.firstaide}/Cargo.lock";
      };

      # for Linux
      nativeBuildInputs = [pkgs.pkg-config];
      buildInputs = [pkgs.openssl];
      # TODO: These probably aren't necessary, but I'm too lazy to test
      PKG_CONFIG_PATH = "${pkgs.openssl.dev.outPath}/lib/pkgconfig:";
      PATH = "${pkgs.pkg-config}/bin";

      meta = {
        description = "Bootstrap tool for Nix environments";
        homepage = "https://github.com/NoRedInk/firstaide";
        mainProgram = "firstaide";
      };
    };
    supportedSystems = with inputs.flake-utils.lib.system; [x86_64-linux x86_64-darwin];
    isSupportedSystem = builtins.elem system supportedSystems;
    outputs = optionalAttrs isSupportedSystem {
      packages =
        {
          inherit (pkgs) nix;
          homeManager = inputs'.home-manager.packages.default;
          firstaide = firstaidePackage;
        }
        // optionalAttrs isDarwin {
          nixDarwin = inputs'.nix-darwin.packages.default;
        };
    };
  in
    outputs;
}
