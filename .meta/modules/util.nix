{ config, lib, ... }:
  rec {
    repo = "${config.home.homeDirectory}/.dotfiles";

    makeSymlinkToRepo = path:
      let
        absolute_path = "${repo}/${path}";
      in
        # Home Manager won't check if link source exists so I'll do it here.
        # issue: https://github.com/nix-community/home-manager/issues/1808
        if builtins.pathExists absolute_path
          then
            config.lib.file.mkOutOfStoreSymlink "${absolute_path}"
          else
            abort "Error: Cannot make out-of-store symlink, the source file does not exist '${absolute_path}'";

    runAfterWriteBoundary = script:
      lib.hm.dag.entryAfter [ "writeBoundary" ] script;

    runAfterLinkGeneration = script:
      lib.hm.dag.entryAfter [ "linkGeneration" ] script;

    runBeforeLinkGeneration = script:
      lib.hm.dag.entryBefore [ "linkGeneration" ] script;

    # destination: path relative to $HOME
    # source: path relative to dotfiles repository
    #
    # TODO: I should recurse into subdirectories
    #
    # TODO: I won't need this if Home Manager gets support for recursive symlinks.
    # issue: https://github.com/nix-community/home-manager/issues/3514
    makeSymlinksToTopLevelFilesInRepo = destination: source:
      let
        absolute_source_path = "${repo}/${source}";
        files = builtins.readDir absolute_source_path;
        links = lib.attrsets.mapAttrs'
          (name: value: lib.attrsets.nameValuePair "${destination}/${name}" { source = makeSymlinkToRepo "${source}/${name}"; })
          files;
      in
        links;
  }
