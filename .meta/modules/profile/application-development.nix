{ config, lib, pkgs, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      makeSymlinkToRepo
      makeSymlinksToTopLevelFilesInRepo
      ;
    ipythonConfigs = makeSymlinksToTopLevelFilesInRepo ".ipython/profile_default/startup" "python/ipython/startup" ../../../python/ipython/startup;
    inherit (specialArgs) xdgPkgs;
  in
    {
      imports = [
        ../unit/direnv.nix
        ../unit/firefox-developer-edition.nix
        ../unit/git.nix
        ../unit/wezterm.nix
        ../unit/keyboard-shortcuts.nix
        ../unit/fonts.nix
      ];

      home.packages = with pkgs; [
        (python3.withPackages(ps: with ps; [pip mypy ipython]))
        nodejs
        rustc
        cargo
        jdk
        lua
        bashInteractive
        yash
        cloudflared
        timg
        xdgPkgs.watchman
        nil
      ];

      home.file = {
        ".ipython/profile_default/ipython_config.py".source = makeSymlinkToRepo "python/ipython/ipython_config.py";
        ".yashrc".source = makeSymlinkToRepo "yash/yashrc";
        ".cloudflared/config.yaml".source = makeSymlinkToRepo "cloudflared/config.yaml";
        ".markdownlint.jsonc".source = makeSymlinkToRepo "markdownlint/markdownlint.jsonc";
        ".vale.ini".source = makeSymlinkToRepo "vale/vale.ini";
        ".local/bin/pynix" = {
          text = ''
            #!${pkgs.fish}/bin/fish

            set packages (printf %s\n $argv | xargs -I PACKAGE echo "python3Packages.PACKAGE")
            ${pkgs.any-nix-shell}/bin/.any-nix-shell-wrapper fish -p $packages

          '';
          executable = true;
        };

      } // ipythonConfigs;

      xdg.configFile = {
        "pip/pip.conf".source = makeSymlinkToRepo "python/pip/pip.conf";
        "vale/styles/base".source = makeSymlinkToRepo "vale/styles/base";
        "vale/styles/ignore.txt".source = makeSymlinkToRepo "vale/styles/ignore.txt";
      };
    }
