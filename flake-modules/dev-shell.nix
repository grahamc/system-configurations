{ lib, inputs, ... }: {
  perSystem = {system, pkgs, ...}: let
    inherit (lib.attrsets) optionalAttrs;

    devShell = pkgs.mkShell {
      packages = with pkgs; [
        just
        lefthook
        fzf
        bashInteractive
        coreutils-full
        moreutils
        nodejs
        deadnix
        treefmt
        nodePackages.prettier
        shfmt
        nixfmt
        stylua
        go
        black
          fish
      ];
    };

    outputs = {
      devShells.default = devShell;
    };

    supportedSystems = with inputs.flake-utils.lib.system; [ x86_64-linux x86_64-darwin ];
    isSupportedSystem = builtins.elem system supportedSystems;
  in
    optionalAttrs isSupportedSystem outputs;
}

