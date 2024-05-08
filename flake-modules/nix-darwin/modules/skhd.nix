{
  specialArgs,
  pkgs,
  lib,
  ...
}: let
  inherit (specialArgs) flakeInputs;
in {
  services = {
    skhd = {
      enable = true;

      package = let
        # all programs transitively called from my skhdrc
        dependencies = pkgs.symlinkJoin {
          name = "skhd-dependencies";
          paths = with pkgs; [
            skhd
            yabai
            fish
            jq
          ];
        };
      in
        pkgs.symlinkJoin {
          name = "my-${pkgs.skhd.name}";
          paths = [pkgs.skhd];
          buildInputs = [pkgs.makeWrapper];
          postBuild = ''
            wrapProgram $out/bin/skhd --prefix PATH : ${lib.escapeShellArg "${dependencies}/bin"} --prefix PATH : ${lib.escapeShellArg "${flakeInputs.self}/dotfiles/skhd/bin"}
          '';
        };
    };
  };
}
