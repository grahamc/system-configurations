{ config, lib, pkgs, ... }:

let
  inherit (lib) types;
  target = lib.mkOption {
    type = types.str;
  };
  source = lib.mkOption {
    type = types.str;
  };
  executable = lib.mkOption {
    type = types.nullOr types.bool;
    default = null;
  };
  recursive = lib.mkOption {
    type = types.bool;
    default = false;
    description = "Top level files only";
  };
  sourcePath = lib.mkOption {
    type = types.nullOr types.path;
    default = null;
    description = ''
      Path to the source directory to be linked recursively. This is required if `recursive` is set
      and ignored otherwise
    '';
  };
  getFileOptions = {name, ...}:
    {
      options = {
        inherit target source executable recursive sourcePath;
      };
      config = {
        target = lib.mkDefault name;
      };
    };
  fileType = types.submodule getFileOptions;
  fileAttrsType = types.attrsOf fileType;
in {
  options.repository.symlink = {
    makeCopiesInstead = lib.mkOption {
      type = types.bool;
      default = false;
    };

    home.file = lib.mkOption {
      type = fileAttrsType;
      default = {};
    };

    xdg = {
      configFile = lib.mkOption {
        type = fileAttrsType;
        default = {};
      };
      dataFile = lib.mkOption {
        type = fileAttrsType;
        default = {};
      };
    };
  };

  config = let
    isRelativePath = path: !lib.hasPrefix "/" path;
    repositoryAbsolutePath = "${config.home.homeDirectory}/${config.repository.path}";
    formatFile = file: let
      absoluteSource = if isRelativePath file.source
        then "${repositoryAbsolutePath}/${file.source}"
        else file.source;
      repoPathAttrs = ../../../../.;
    in {
      # Exclude the attributes that aren't in the original file type.
      inherit (file) target executable;
      source = if config.repository.symlink.makeCopiesInstead
        then repoPathAttrs + (lib.strings.removePrefix repositoryAbsolutePath absoluteSource)
        else config.lib.file.mkOutOfStoreSymlink absoluteSource;
    };
    # TODO: I won't need this if Home Manager gets support for recursive symlinks.
    # issue: https://github.com/nix-community/home-manager/issues/3514
    getFormattedTopLevelFiles = directory:
      let
        files = builtins.readDir directory.sourcePath;
        formattedFiles = lib.attrsets.mapAttrs'
          (name: value:
            lib.attrsets.nameValuePair
              "${directory.target}/${name}"
              (formatFile {source = "${directory.source}/${name}"; target = "${directory.target}/${name}"; inherit (directory) executable;})
          )
          files;
      in
        formattedFiles;
    formatFileSet = fileSet:
      lib.attrsets.foldlAttrs
        (acc: name: value:
          let
            item = if (builtins.hasAttr "recursive" value) && value.recursive
              then (getFormattedTopLevelFiles value)
              else {${name} = (formatFile value);};
          in
            acc // item
        )
        {}
        fileSet;
  in
    {
      assertions = [
        {
          assertion = let
            fileSets = with config.repository.symlink; [home.file xdg.configFile xdg.dataFile];
            isRecursiveWithoutSourcePath = file: file.recursive && file.sourcePath == null;
            isInvalid = lib.lists.any
              lib.trivial.id
              (lib.lists.flatten
                (map
                  (fileSet:
                    (map
                      isRecursiveWithoutSourcePath
                      (builtins.attrValues fileSet)
                    )
                  )
                  fileSets
                )
              );
          in
            !isInvalid;
          message = "The recursive option is set, but no sourcePath was given.";
        }
      ];
      home.file = formatFileSet config.repository.symlink.home.file;
      xdg.configFile = formatFileSet config.repository.symlink.xdg.configFile;
      xdg.dataFile = formatFileSet config.repository.symlink.xdg.dataFile;
    };
}
