{lib, flake-parts-lib, inputs, ... }:
  let
    inherit (lib) mkOption types;
    inherit (lib.attrsets) optionalAttrs;
    inherit (flake-parts-lib) mkTransposedPerSystemModule;

    recursiveMerge = sets: lib.lists.foldr lib.recursiveUpdate {} sets;
    bundlerOption = mkTransposedPerSystemModule {
      name = "bundlers";
      option = mkOption {
        type = types.anything;
        default = { };
      };
      file = ./bundler.nix;
    };
    bundlerOutput = {
      config = {
        perSystem = {system, ...}:
          # This output is the bundler that I use to build an executable of the app output defined earlier in this flake.
          # I could just reference this bundler with `nix bundle --bundler github:ralismark/nix-appimage .#`, but
          # then it wouldn't be pinned to a revision. To pin it, I include it as an input and use the bundler output
          # below.
          optionalAttrs
            (builtins.elem system (with inputs.flake-utils.lib.system; [ x86_64-linux ]))
            { bundlers = inputs.nix-appimage.bundlers.${system}; };
      };
    };
  in
    # They both have a 'config' key so I need to merge recursively
    recursiveMerge [ bundlerOption bundlerOutput ]

