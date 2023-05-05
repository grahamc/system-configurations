{ config, lib, specialArgs, ... }:
  {
    symlink.home.file = {
      # I link to this directory from other modules so I make sure the key here is unique and specify the target
      # inside the attribute set.
      ".local/bin (general)" = {
        source = "general/executables";
        sourcePath = ../../general/executables;
        recursive = true;
      };
    };
  }
