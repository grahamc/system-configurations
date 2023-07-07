{ config, lib, specialArgs, ... }:
  {
    repository.symlink.xdg.executable = {
      "general executables" = {
        source = "general/executables";
        recursive = true;
      };
    };

    # I'm not symlinking the whole directory because EmmyLua is going to generate lua-language-server annotations
    # in there.
    home.file.".hammerspoon/Spoons/EmmyLua.spoon" = {
      source = "${specialArgs.flakeInputs.spoons}/Source/EmmyLua.spoon";
      recursive = true;
    };
  }
