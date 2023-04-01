{ config, lib, pkgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlink
      makeOutOfStoreSymlinksForTopLevelFiles
      ;
    ipythonConfigs = makeOutOfStoreSymlinksForTopLevelFiles ".ipython/profile_default/startup" "python/ipython/startup";
  in
    {
      imports = [
        ../unit/direnv.nix
        ../unit/firefox-developer-edition.nix
        ../unit/git.nix
        ../unit/kitty.nix
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
        ".ipython/profile_default/ipython_config.py".source = makeOutOfStoreSymlink "python/ipython/ipython_config.py";
        ".yashrc".source = makeOutOfStoreSymlink "yash/yashrc";
        ".cloudflared/config.yaml".source = makeOutOfStoreSymlink "cloudflared/config.yaml";
        ".markdownlint.jsonc".source = makeOutOfStoreSymlink "markdownlint/markdownlint.jsonc";
        ".vale.ini".source = makeOutOfStoreSymlink "vale/vale.ini";
      } // ipythonConfigs;

      xdg.configFile = {
        "pip/pip.conf".source = makeOutOfStoreSymlink "python/pip/pip.conf";
        "vale/styles/base".source = makeOutOfStoreSymlink "vale/styles/base";
        "vale/styles/ignore.txt".source = makeOutOfStoreSymlink "vale/styles/ignore.txt";
      };
    }
