{
  lib,
  pkgs,
  specialArgs,
  ...
}: let
  fzfWithoutShellConfig = pkgs.buildEnv {
    name = "fzf-without-shell-config";
    paths = [pkgs.fzf];
    pathsToLink = ["/bin" "/share/man"];
  };
in {
  home.packages = [
    fzfWithoutShellConfig
  ];

  programs.fish.interactiveShellInit = ''
    fish_add_path --global --prepend ${lib.escapeShellArg "${specialArgs.flakeInputs.self}/dotfiles/fzf/bin"}
  '';

  repository.symlink.xdg.configFile = {
    "fish/conf.d/fzf-default-opts.fish".source = "fzf/fzf-default-opts.fish";
  };

  home.activation.fzfSetup =
    lib.hm.dag.entryAfter
    ["writeBoundary"]
    ''
      history_file="''${XDG_DATA_HOME:-''$HOME/.local/share}/fzf/fzf-history.txt"
      mkdir -p "$(dirname "$history_file")"
      touch "$history_file"
    '';
}
