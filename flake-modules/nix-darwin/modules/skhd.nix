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

      package = pkgs.symlinkJoin {
        name = "my-${pkgs.skhd.name}";
        paths = [pkgs.skhd];
        buildInputs = [pkgs.makeWrapper];
        # skhd needs itself on the $PATH for any of the shortcuts in my skhdrc
        # that use the skhd command to send keys.
        postBuild = ''
          wrapProgram $out/bin/skhd --prefix PATH : ${lib.escapeShellArg "${pkgs.skhd}/bin"} --prefix PATH : ${lib.escapeShellArg "${flakeInputs.self}/dotfiles/skhd/bin"}
        '';
      };
    };
  };
}
