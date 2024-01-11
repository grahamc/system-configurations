{
  specialArgs,
  pkgs,
  ...
}: let
  inherit (specialArgs) homeDirectory;
in {
  environment = {
    profiles = [
      # skhd needs my yabai-* scripts
      "${homeDirectory}/.local"
    ];
  };

  services = {
    skhd = {
      enable = true;

      # skhd needs itself on the $PATH for any of the shortcuts in my skhdrc that use the skhd
      # command to send keys.
      package = pkgs.writeShellApplication {
        name = "skhd";
        runtimeInputs = with pkgs; [skhd];
        text = ''exec skhd "$@" '';
      };
    };
  };
}
