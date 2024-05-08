{
  pkgs,
  lib,
  ...
}: {
  services = {
    yabai = {
      enable = true;
      enableScriptingAddition = true;
      package = let
        # all programs called from my yabairc
        dependencies = pkgs.symlinkJoin {
          name = "yabai-dependencies";
          paths = with pkgs; [
            jq
            yabai
          ];
        };
      in
        pkgs.symlinkJoin {
          name = "my-${pkgs.yabai.name}";
          paths = [pkgs.yabai];
          buildInputs = [pkgs.makeWrapper];
          postBuild = ''
            wrapProgram $out/bin/yabai --prefix PATH : ${lib.escapeShellArg "${dependencies}/bin"}
          '';
        };
    };
  };
}
