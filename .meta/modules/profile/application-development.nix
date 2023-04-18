{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeSymlinkToRepo
      makeSymlinksToTopLevelFilesInRepo
      ;
    ipythonConfigs = makeSymlinksToTopLevelFilesInRepo ".ipython/profile_default/startup" "python/ipython/startup";
  in
    {
      imports = [
        ../unit/direnv.nix
        ../unit/firefox-developer-edition.nix
        ../unit/git.nix
        ../unit/wezterm.nix
        ../unit/vscode.nix
      ];

      home.packages = with pkgs; [
        (python3.withPackages(ps: with ps; [pip mypy ipython]))
        nodejs
        rustc
        cargo
        jdk
        go
        bashInteractive
        yash
        languagetool
        cloudflared
      ];

      home.file = {
        ".ipython/profile_default/ipython_config.py".source = makeSymlinkToRepo "python/ipython/ipython_config.py";
        ".yashrc".source = makeSymlinkToRepo "yash/yashrc";
        ".cloudflared/config.yaml".source = makeSymlinkToRepo "cloudflared/config.yaml";
        ".markdownlint.jsonc".source = makeSymlinkToRepo "markdownlint/markdownlint.jsonc";
        ".vale.ini".source = makeSymlinkToRepo "vale/vale.ini";
        ".local/bin/pynix" = {
          text = ''
            #!/bin/bash

            ${pkgs.any-nix-shell}/bin/.any-nix-shell-wrapper fish -p "python3.withPackages (ps: with ps; [ "$@" ])"
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
