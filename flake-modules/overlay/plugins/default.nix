{
  inputs,
  lib,
  self,
  ...
}: {
  imports = [
    ./fish-plugins.nix
    ./vim-plugins.nix
  ];

  flake = let
    # repositoryPrefix:
    # builder: (repositoryName: repositorySourceCode: date: derivation)
    #
    # returns: A set with the form {<repo name with `repositoryPrefix` removed> = derivation}
    makePluginPackages = repositoryPrefix: builder: let
      filterRepositoriesForPrefix = repositories: let
        hasPrefix = string: (builtins.match "${repositoryPrefix}.*" string) != null;
      in
        lib.attrsets.filterAttrs
        (repositoryName: _ignored: hasPrefix repositoryName)
        repositories;

      removePrefixFromRepositories = repositories:
        lib.mapAttrs'
        (
          repositoryName: repositorySourceCode: let
            repositoryNameWithoutPrefix = lib.strings.removePrefix repositoryPrefix repositoryName;
          in
            lib.nameValuePair
            repositoryNameWithoutPrefix
            repositorySourceCode
        )
        repositories;

      buildPackagesFromRepositories = repositories: let
        buildPackage = repositoryName: repositorySourceCode: let
          # YYYYMMDDHHMMSS -> YYYY-MM-DD
          formatDate = date: let
            yearMonthDayStrings = builtins.match "(....)(..)(..).*" date;
          in
            lib.concatStringsSep "-" yearMonthDayStrings;

          date = formatDate repositorySourceCode.lastModifiedDate;
        in
          builder repositoryName repositorySourceCode date;
      in
        lib.mapAttrs buildPackage repositories;
    in
      lib.trivial.pipe
      inputs
      [filterRepositoriesForPrefix removePrefixFromRepositories buildPackagesFromRepositories];
  in {
    lib.pluginOverlay = {inherit makePluginPackages;};
    overlays.plugins = lib.composeManyExtensions [
      self.overlays.vimPlugins
      self.overlays.fishPlugins
    ];
  };
}
