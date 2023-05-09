{ config, lib, specialArgs, ... }:
  {
    repository.symlink.home.file = {
      # I link to this directory from other modules so I make sure the key here is unique and specify the target
      # inside the attribute set.
      ".local/bin (general)" = {
        target = ".local/bin";
        source = "general/executables";
        recursive = true;
      };
    };
  }
