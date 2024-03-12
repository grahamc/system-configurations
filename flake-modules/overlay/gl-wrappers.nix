# Wrap the specified list of packages with nixGL so they work correctly on non-NixOS linux systems.
#
# Most of the implementation came from here:
# https://github.com/nix-community/nixGL/issues/140#issuecomment-1950754800
#
# TODO: nixGL is considering adding something like this:
# https://github.com/nix-community/nixGL/issues/140
#
# TODO: Nix is trying to fix this issue:
# https://github.com/NixOS/nixpkgs/issues/62169
# https://github.com/NixOS/nixpkgs/issues/9415
{
  inputs,
  lib,
  ...
}: {
  flake = let
    makeGLWrapperOverlayForPackages = pkgNames: final: prev: let
      wrapPackage = pkgName: let
        pkg = prev.${pkgName};
        mainProgramName =
          if builtins.hasAttr "mainProgram" pkg.meta
          then pkg.meta.mainProgram
          else null;
        # Merge with the original package to retain attributes like meta, terminfo, etc.
        wrappedMainProgram =
          pkg
          // final.symlinkJoin {
            name = "${pkg.name}-with-nixgl";
            paths = let
              wrappedMainProgram = final.writeShellScriptBin mainProgramName ''
                exec ${inputs.nixgl.packages.${final.system}.nixGLDefault}/bin/nixGL ${pkg}/bin/${mainProgramName} "$@"
              '';
            in
              [wrappedMainProgram] ++ [pkg];
            inherit (pkg) meta;
          };
      in
        if mainProgramName == null
        then builtins.throw "[gl-wrapper]: Unable to wrap '${pkg.name}', no mainProgram is defined for it."
        else wrappedMainProgram;
    in
      lib.optionalAttrs prev.stdenv.isLinux (builtins.listToAttrs (builtins.map (pkgName: {
          name = pkgName;
          value = wrapPackage pkgName;
        })
        pkgNames));
  in {
    overlays.glWrappers = makeGLWrapperOverlayForPackages [
      "wezterm"
    ];
  };
}
