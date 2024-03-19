# This output makes it easy to build all the packages that I want to cache in my cloud-hosted Nix
# package cache. I build this package from CI and cache everything that gets added to the Nix store
# as a result of building it.
_: {
  perSystem = {
    self',
    pkgs,
    lib,
    ...
  }: let
    inherit (lib.attrsets) optionalAttrs mapAttrs hasAttrByPath attrByPath getAttrFromPath;

    homeManagerPackagesByName = let
      homeManagerOutputsByHostName = attrByPath ["legacyPackages" "homeConfigurations"] {} self';
    in
      mapAttrs (_hostName: output: output.activationPackage) homeManagerOutputsByHostName;

    nixDarwinPackagesByName = let
      nixDarwinOutputsByHostName = attrByPath ["legacyPackages" "darwinConfigurations"] {} self';
    in
      mapAttrs (_hostName: output: output.system) nixDarwinOutputsByHostName;

    devShellsByName = let
      devShellOutputsKey = "devShells";
    in
      optionalAttrs
      (builtins.hasAttr devShellOutputsKey self')
      (builtins.getAttr devShellOutputsKey self');

    # Where simple means a package exposed in this flake that supports every system the flake
    # supports.
    simplePackages =
      builtins.foldl'
      (
        acc: name: let
          outputPath = ["packages" name];
        in
          acc
          // optionalAttrs
          (hasAttrByPath outputPath self')
          {"${name}" = getAttrFromPath outputPath self';}
      )
      {}
      [
        "homeManager"
        "nixDarwin"
        "nix"
      ];

    packagesToCacheByName =
      homeManagerPackagesByName
      // nixDarwinPackagesByName
      // devShellsByName
      // simplePackages;

    outputs = {
      packages.default = pkgs.linkFarm "packages-to-cache" packagesToCacheByName;
    };
  in
    outputs;
}
