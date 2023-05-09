{ ... }:
  {
    perSystem = {self', pkgs, lib, ...}:
      let
        inherit (lib.attrsets) optionalAttrs mapAttrs hasAttrByPath attrByPath getAttrFromPath;
        homeManagerPackagesByName =
          let
            homeManagerOutputsByHostName = attrByPath ["legacyPackages" "homeConfigurations"] {} self';
          in
            (mapAttrs (hostName: output: output.activationPackage) homeManagerOutputsByHostName);
        nixDarwinPackagesByName =
          let
            nixDarwinOutputsByHostName = attrByPath ["legacyPackages" "darwinConfigurations"] {} self';
          in
            (mapAttrs (hostName: output: output.system) nixDarwinOutputsByHostName);
        shellPackageByName = 
          let
            shellOutputPath = ["packages" "shell"];
          in
            optionalAttrs
              (hasAttrByPath shellOutputPath self')
              {shell = (getAttrFromPath shellOutputPath self');};
        packagesToCacheByName = homeManagerPackagesByName // nixDarwinPackagesByName // shellPackageByName;
        outputs = {
          packages.default = pkgs.linkFarm "packages-to-cache" packagesToCacheByName;
        };
      in
        outputs;
  }
