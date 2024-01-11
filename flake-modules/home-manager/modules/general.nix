{
  pkgs,
  lib,
  specialArgs,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (pkgs.stdenv) isDarwin;
in {
  repository.symlink.xdg.executable =
    {
      "myeditor".source = "general/executables/myeditor";
      "pbcopy".source = "general/executables/pbcopy";
      "process-output".source = "general/executables/process-output";
    }
    // optionalAttrs isDarwin {
      "trash".source = "general/executables/trash.py";
    };

  # I'm not symlinking the whole directory because EmmyLua is going to generate
  # lua-language-server annotations in there.
  home.file = optionalAttrs isDarwin {
    ".hammerspoon/Spoons/EmmyLua.spoon" = {
      source = "${specialArgs.flakeInputs.spoons}/Source/EmmyLua.spoon";
      recursive = true;
    };
  };
}
