{
  flake-parts-lib,
  lib,
  ...
}: let
  inherit (flake-parts-lib) mkTransposedPerSystemModule;
  inherit (lib) mkOption types;
  bundlerOption = mkTransposedPerSystemModule {
    name = "bundlers";
    option = mkOption {
      type = types.anything;
      default = {};
    };
    file = ./option.nix;
  };
in
  bundlerOption
