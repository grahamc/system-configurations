# This module makes it easy to create symlinks to a file in your Home Manager repository. This way you
# can edit a file and have the changes applied instantly without having to switch generations.
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
  getFileOptions = {name, ...}:
    {
      options = {
        inherit target source executable recursive;
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

    baseDirectory = lib.mkOption {
      type = types.str;
      description = "Absolute path to the directory inside the Home Manager flake that the relative paths are relative to.";
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
    makePathStringAbsolute = path:
      if isRelativePath path
        then "${config.repository.symlink.baseDirectory}/${path}"
        else path;
    # The file has to be in the flake because you can't reference files outside the flake in pure evaluation mode.
    convertAbsolutePathStringToPath = pathString:
      let
        homeManagerFlakeDirectoryPath = ../../../.;
        homeManagerFlakeDirectory = "${config.repository.directory}/home";
        pathStringRelativeToHomeManager = (lib.strings.removePrefix homeManagerFlakeDirectory pathString);
        path = homeManagerFlakeDirectoryPath + pathStringRelativeToHomeManager;
      in
        path;
    filterNonHomeManagerFileAttributes = file:
      let
        homeManagerFileAttributeNames = ["source" "target" "executable"];
        isHomeManagerFileAttributeName = name: builtins.elem name homeManagerFileAttributeNames;
        filteredSet = lib.attrsets.filterAttrs
          (name: value: isHomeManagerFileAttributeName name)
          file;
      in
        filteredSet;
    convertFileToHomeManagerSymlinkedFile = file: let
      absoluteSource = makePathStringAbsolute file.source;
      symlinkSource = if config.repository.symlink.makeCopiesInstead
        then convertAbsolutePathStringToPath absoluteSource
        else config.lib.file.mkOutOfStoreSymlink absoluteSource;
      symlinkFile = file // { source = symlinkSource; };
      homeManagerSymlink = filterNonHomeManagerFileAttributes symlinkFile;
    in
      homeManagerSymlink;
    # TODO: I won't need this if Home Manager gets support for recursive symlinks.
    # issue: https://github.com/nix-community/home-manager/issues/3514
    getSymlinksToTopLevelFiles = directory:
      let
        sourceAbsolutePathString = makePathStringAbsolute directory.source;
        sourcePath = convertAbsolutePathStringToPath sourceAbsolutePathString;
        files = builtins.readDir sourcePath;
        symlinks = lib.attrsets.mapAttrs'
          (name: value:
            lib.attrsets.nameValuePair
              "${directory.target}/${name}"
              (convertFileToHomeManagerSymlinkedFile {source = "${directory.source}/${name}"; target = "${directory.target}/${name}"; inherit (directory) executable;})
          )
          files;
      in
        symlinks;
    formatFileSet = fileSet:
      lib.attrsets.foldlAttrs
        (acc: name: value:
          let
            item = if (builtins.hasAttr "recursive" value) && value.recursive
              then (getSymlinksToTopLevelFiles value)
              else {${name} = (convertFileToHomeManagerSymlinkedFile value);};
          in
            acc // item
        )
        {}
        fileSet;
  in
    {
      home.file = formatFileSet config.repository.symlink.home.file;
      xdg.configFile = formatFileSet config.repository.symlink.xdg.configFile;
      xdg.dataFile = formatFileSet config.repository.symlink.xdg.dataFile;
    };
}
