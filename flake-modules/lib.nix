{
  lib,
  flake-parts-lib,
  ...
}: {
  options = {
    flake = flake-parts-lib.mkSubmoduleOptions {
      lib = lib.mkOption {
        # types.anything recursively merges its values, which I don't want, so I wrapped it in uniq
        type = lib.types.attrsOf (lib.types.uniq lib.types.anything);
        default = {};
        internal = true;
        description = "Utilties for other flake modules to use.";
      };
    };
  };

  config = {
    flake = {
      # This applies `nixpkgs.lib.recursiveUpdate` to a list of sets, instead of just two.
      lib.recursiveMerge = sets: lib.lists.foldr lib.recursiveUpdate {} sets;
    };
  };
}
