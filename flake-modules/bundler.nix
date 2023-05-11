{lib, flake-parts-lib, inputs, ... }:
  let
    inherit (lib) mkOption types;
    inherit (lib.attrsets) optionalAttrs;
    inherit (flake-parts-lib) mkTransposedPerSystemModule;

    recursiveMerge = sets: lib.lists.foldr lib.recursiveUpdate {} sets;

    bundlerOutputKey = "bundlers";

    bundlerOption = mkTransposedPerSystemModule {
      name = bundlerOutputKey;
      option = mkOption {
        type = types.anything;
        default = {};
      };
      file = ./bundler.nix;
    };

    # This output is the bundler that I use to build an executable of the app output in this flake.
    # I could just reference this bundler with `nix bundle --bundler <flakeref> .#`, but
    # then it wouldn't be pinned to a version. To pin it, I include it as a flake input, thus adding it to my
    # `flack.lock`. To use it, I expose that pinned version through the flake output below.
    bundlerConfig = {
      config = {
        perSystem = {system, ...}:
          let
            supportedSystems = with inputs.flake-utils.lib.system; [ x86_64-linux ];
            isSupportedSystem = builtins.elem system supportedSystems;
            bundlerOutput = {
              ${bundlerOutputKey} = inputs.nix-appimage.${bundlerOutputKey}.${system};
            };
          in
            optionalAttrs isSupportedSystem bundlerOutput;
      };
    };
  in
    # They both have a 'config' key so I need to merge recursively
    recursiveMerge [ bundlerOption bundlerConfig ]

