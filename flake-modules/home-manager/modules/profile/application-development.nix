{pkgs, ...}: let
  pythonWithPackages = pkgs.python3.withPackages (ps: with ps; [pip mypy ipython]);

  # TODO: Python virtualenvs use the canonical path of the base python. This is an issue for Nix
  # because when I update my system and the old python gets garbage collected, it breaks any
  # virtualenvs made against it. So I made a wrapper that injects the --copies flag whenever a
  # virtualenv is being made.
  wrappedPython3 = let
    python3CopyVenvsByDefault =
      pkgs.writeShellApplication
      {
        name = "python";
        text = ''
          new_args=()
          seen_m=""
          seen_venv=""
          for arg in "$@"; do
            new_args=("''${new_args[@]}" "$arg")
            if [ "$arg" = '-m' ]; then
              seen_m=1
            elif [ -n "$seen_m" ] && [ -z "$seen_venv" ] && [ "$arg" = 'venv' ] && [ -z "''${BIGOLU_NO_COPY:-}" ]; then
              new_args=("''${new_args[@]}" "--copies")
              seen_venv=1
              printf '\nInjecting the "--copies" flag into the venv command. This is to avoid breaking virtual environments when Nix does garbage collection. You can disable this injection by setting the environment variable "BIGOLU_NO_COPY=1"\n\n'
            fi
          done

          exec ${pythonWithPackages}/bin/python "''${new_args[@]}"
        '';
      };

    python3CopyVenvsByDefaultPackage =
      pkgs.runCommand
      "python-copy-venvs"
      {}
      ''
        mkdir -p $out/bin
        name="$(find ${pythonWithPackages}/bin -printf '%f\n' | grep -E '^python3\.[0-9]+(\.[0-9]+)?$')"
        cp ${python3CopyVenvsByDefault}/bin/python "$out/bin/$name"
        cp ${python3CopyVenvsByDefault}/bin/python "$out/bin/python"
        cp ${python3CopyVenvsByDefault}/bin/python "$out/bin/python3"
      '';
  in
    pkgs.symlinkJoin {
      name = "python-copy-venvs";
      paths = [
        python3CopyVenvsByDefaultPackage
        pythonWithPackages
      ];
    };
in {
  imports = [
    ../direnv.nix
    ../firefox-developer-edition.nix
    ../git.nix
    ../wezterm.nix
  ];

  home.packages = with pkgs; [
    wrappedPython3
    nodejs
    deno
    typescript
    rustc
    go
    cargo
    jdk
    lua
    bashInteractive
    yash
    cloudflared
    timg
    nil
    ast-grep
    watchexec
  ];

  repository.symlink = {
    home.file = {
      ".yashrc".source = "yash/yashrc";
      ".cloudflared/config.yaml".source = "cloudflared/config.yaml";
      ".markdownlint.jsonc".source = "markdownlint/markdownlint.jsonc";
    };

    xdg.configFile = {
      "pip/pip.conf".source = "python/pip/pip.conf";
      "ipython/profile_default/ipython_config.py".source = "python/ipython/ipython_config.py";
      "ipython/profile_default/startup" = {
        source = "python/ipython/startup";
        recursive = true;
      };
    };
  };
}
