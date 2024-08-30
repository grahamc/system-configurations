{
  lib,
  inputs,
  ...
}: {
  perSystem = {
    system,
    pkgs,
    ...
  }: let
    inherit (lib.attrsets) optionalAttrs;

    # Make a meta-package so we don't have a $PATH entry for each package
    metaPackage = pkgs.symlinkJoin {
      name = "tools";
      paths = with pkgs; [
        # languages
        bashInteractive
        go
        nix
        lua

        # formatters and linters
        black
        usort
        deadnix
        statix
        treefmt
        nodePackages.prettier
        shfmt
        alejandra
        stylua
        fish # for fish_indent
        renovate # for renovate-config-validator
        actionlint

        # version control
        git
        lefthook

        # for the Nix IDE vscode extension
        nil

        # various shell script dependencies
        coreutils-full
        moreutils
        findutils
        jq
        which
        gnused
        gnugrep

        # misc.
        just
        doctoc
      ];

      # TODO: Nix should be able to link in prettier, I think it doesn't work
      # because the `prettier` is a symlink
      postBuild = ''
        cd $out/bin
        ln -s ${pkgs.nodePackages.prettier}/bin/prettier ./prettier
      '';
    };

    outputs = {
      # The devShell contains a lot of environment variables that are irrelevant
      # to our development environment, but Nix is working on a solution to
      # that: https://github.com/NixOS/nix/issues/7501
      devShells.default = pkgs.mkShellNoCC {
        packages = [
          metaPackage
        ];
      };
    };

    supportedSystems = with inputs.flake-utils.lib.system; [x86_64-linux x86_64-darwin];
    isSupportedSystem = builtins.elem system supportedSystems;
  in
    optionalAttrs isSupportedSystem outputs;
}
