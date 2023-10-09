{ config, pkgs, specialArgs, ... }:
  {
    home.packages = with pkgs; [
      direnv
      nix-direnv
    ];

    repository.symlink.xdg.configFile = {
      "direnv/direnv.toml".source = "direnv/direnv.toml";
    };

    xdg.configFile = {
      # I'm using an out-of-store symlink because since links are generated before programs are installed, if
      # nix-direnv hasn't been installed yet, a regular symlink would throw an error. For out-of-store links
      # however, Home Manager doesn't require that the source file exists before making the link.
      "direnv/lib/use_nix_direnv.sh".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/share/nix-direnv/direnvrc";

      "fish/conf.d/direnv.fish".source = ''${
        pkgs.runCommand "direnv-config.fish" {} "${pkgs.direnv}/bin/direnv hook fish > $out"
      }'';
    };
  }
