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
    supportedSystems = with inputs.flake-utils.lib.system; [x86_64-linux x86_64-darwin];
    isSupportedSystem = builtins.elem system supportedSystems;
    outputs = optionalAttrs isSupportedSystem {
      packages =
        {
          homeManager = inputs'.home-manager.packages.default;
        }
        // optionalAttrs isDarwin {
          nixDarwin = inputs'.nix-darwin.packages.default;
        };
    };
  in
    outputs;
}
