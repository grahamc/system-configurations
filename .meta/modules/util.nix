{ config, lib, ... }:
  rec {
    repo = "${config.home.homeDirectory}/.dotfiles";

    makeSymlinkToRepo = path:
      let
        absolute_path = "${repo}/${path}";
      in
        config.lib.file.mkOutOfStoreSymlink "${absolute_path}";

    runAfterWriteBoundary = script:
      lib.hm.dag.entryAfter [ "writeBoundary" ] script;

    runAfterLinkGeneration = script:
      lib.hm.dag.entryAfter [ "linkGeneration" ] script;

    runBeforeLinkGeneration = script:
      lib.hm.dag.entryBefore [ "linkGeneration" ] script;

    # destination: path relative to $HOME
    # sourceString: path string to the source, relative to the root dotfiles repository
    # sourcePath: Path to the source
    #
    # TODO: I won't need this if Home Manager gets support for recursive symlinks.
    # issue: https://github.com/nix-community/home-manager/issues/3514
    makeSymlinksToTopLevelFilesInRepo = destination: sourceString: sourcePath:
      let
        files = builtins.readDir sourcePath;
        links = lib.attrsets.mapAttrs'
          (name: value:
            lib.attrsets.nameValuePair
              "${destination}/${name}"
              { source = makeSymlinkToRepo "${sourceString}/${name}"; }
          )
          files;
      in
        links;
  }
