{lib, inputs, ... }:
  let
    inherit (lib.attrsets) optionalAttrs;
    bundlerOutputKey = "bundlers";
  in
    {
      imports = [
        # I defined this in a separate file to avoid an infinite recursion. The function use in option.nix that makes
        # the bundler option return a set with the keys `config` and `option`. The set returned here would also have
        # a `config` key, for the perSystem. To combine the two, I would use my helper function
        # `self.lib.recursiveMerge`. It needs to be recursive since they both share a config key. I get an infinite
        # recursion because the output of the call to self.lib.recursiveMerge would affect the value of self.
        ./option.nix
      ];

      perSystem = {system, ...}:
        let
          supportedSystems = with inputs.flake-utils.lib.system; [ x86_64-linux ];
          isSupportedSystem = builtins.elem system supportedSystems;
          # This output is the bundler that I use to build an executable of the app output in this flake.
          # I could just reference this bundler with `nix bundle --bundler <flakeref> .#`, but
          # then it wouldn't be pinned to a version. To pin it, I include it as a flake input, thus adding it to my
          # `flack.lock`. To use it, I expose that pinned version through the flake output below.
          bundlerOutput = {
            ${bundlerOutputKey} = inputs.nix-appimage.${bundlerOutputKey}.${system};
          };
        in
          optionalAttrs isSupportedSystem bundlerOutput;
    }
    
