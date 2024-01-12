# This output makes it easy to build all the packages that I want to cache in my cloud-hosted Nix package cache.
# I build this package from CI and cache everything that gets added to the Nix store as a result of building it.
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

    shellPackageByName = let
      shellOutputPath = ["packages" "shell"];
    in
      optionalAttrs
      (hasAttrByPath shellOutputPath self')
      {shell = getAttrFromPath shellOutputPath self';};

    terminalPackageByName = let
      terminalOutputPath = ["packages" "terminal"];
    in
      optionalAttrs
      (hasAttrByPath terminalOutputPath self')
      {terminal = getAttrFromPath terminalOutputPath self';};

    devShellsByName = let
      devShellOutputsKey = "devShells";
    in
      optionalAttrs
      (builtins.hasAttr devShellOutputsKey self')
      (builtins.getAttr devShellOutputsKey self');

    homeManagerPackageByName = let
      homeManagerOutputPath = ["packages" "homeManager"];
    in
      optionalAttrs
      (hasAttrByPath homeManagerOutputPath self')
      {homeManager = getAttrFromPath homeManagerOutputPath self';};

    nixDarwinPackageByName = let
      nixDarwinOutputPath = ["packages" "nixDarwin"];
    in
      optionalAttrs
      (hasAttrByPath nixDarwinOutputPath self')
      {nixDarwin = getAttrFromPath nixDarwinOutputPath self';};

    packagesToCacheByName =
      homeManagerPackagesByName
      // nixDarwinPackagesByName
      // shellPackageByName
      // terminalPackageByName
      // devShellsByName
      // homeManagerPackageByName
      // nixDarwinPackageByName;

    outputs = {
      packages.default = pkgs.linkFarm "packages-to-cache" packagesToCacheByName;
    };
  in
    outputs;
}
