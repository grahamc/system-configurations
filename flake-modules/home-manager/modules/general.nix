{ config, lib, specialArgs, ... }:
  {
    repository.symlink.xdg.executable = {
      "general executables" = {
        source = "general/executables";
        recursive = true;
      };
    };
  }
