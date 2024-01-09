# This module has the configuration that I always want applied.

{ specialArgs, ... }: let
  inherit (specialArgs) homeDirectory;
in {
  imports = [
    ../homebrew.nix
    ../nix.nix
    ../nix-darwin.nix
    ../system-settings.nix
    ../skhd.nix
    ../yabai.nix
  ];

  programs.bash.enable = false;

  environment = {
    profiles = [
      # TODO: Adding my user profile here so that it's `/bin` directory gets added to the
      # $PATH of `launchd.user.agents`. nix-darwin attempts to do this, but it uses
      # '$HOME/.nix-profile' and '$HOME' never gets expanded.
      # issue: https://github.com/LnL7/nix-darwin/issues/406
      "${homeDirectory}/.nix-profile"
    ];
  };
}
