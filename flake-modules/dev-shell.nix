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
        alejandra
        stylua
        go
        black
        fish
        statix
        ast-grep
        jq
      ];
    };

    outputs = {
      devShells.default = devShell;
    };

    supportedSystems = with inputs.flake-utils.lib.system; [x86_64-linux x86_64-darwin];
    isSupportedSystem = builtins.elem system supportedSystems;
  in
    optionalAttrs isSupportedSystem outputs;
}
