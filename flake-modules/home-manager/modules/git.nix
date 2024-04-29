{
  pkgs,
  lib,
  specialArgs,
  ...
}: {
  home.packages = with pkgs; [
    gitMinimal
    delta
  ];

  repository.symlink.xdg.configFile = {
    "git/config".source = "git/config";
  };

  programs.fish.interactiveShellInit = ''
    fish_add_path --global --prepend ${lib.escapeShellArg "${specialArgs.flakeInputs.self}/dotfiles/git/bin"}
  '';
}
