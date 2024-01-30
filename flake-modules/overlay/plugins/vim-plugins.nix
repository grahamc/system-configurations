{
  inputs,
  self,
  lib,
  ...
}: {
  flake = let
    overlay = final: prev: let
      vimPluginRepositoryPrefix = "vim-plugin-";

      vimPluginBuilder = repositoryName: repositorySourceCode: date: let
        package =
          if builtins.hasAttr repositoryName prev.vimPlugins
          then
            (builtins.getAttr repositoryName prev.vimPlugins).overrideAttrs (_old: {
              name = "${repositoryName}-${date}";
              version = date;
              src = repositorySourceCode;
            })
          else
            prev.vimUtils.buildVimPlugin {
              pname = repositoryName;
              version = date;
              src = repositorySourceCode;
            };
      in
        # TODO: I'm doing this because vim-plug won't let me lazy-load a plugin unless it
        # has a folder named 'plugin'.
        #
        # I merge this new package with the old one so I can retain any attributes from
        # the old one that the new one doesn't have, like nvim-treesitter.withPlugins.
        package
        // (final.symlinkJoin {
          name = repositoryName;
          version = date;
          paths = [package];
          postBuild = ''
            cd $out
            [ -d ./plugin ] || mkdir plugin
          '';
        });

      newVimPlugins =
        self.lib.pluginOverlay.makePluginPackages
        vimPluginRepositoryPrefix
        vimPluginBuilder;

      nvim-treesitter = let
        just-grammar = final.tree-sitter.buildGrammar {
          language = "just";
          version = inputs.tree-sitter-just.rev;
          src = inputs.tree-sitter-just;
        };
        dap-repl-grammar = final.tree-sitter.buildGrammar {
          language = "dap_repl";
          version = inputs.vim-plugin-nvim-dap-repl-highlights.rev;
          src = inputs.vim-plugin-nvim-dap-repl-highlights;
        };
        updatedGrammars = newVimPlugins.nvim-treesitter.allGrammars ++ [just-grammar dap-repl-grammar];
        package = newVimPlugins.nvim-treesitter.withPlugins (_: updatedGrammars);
      in
        package // {withAllGrammars = package;};

      lua-json5 = let
        inherit (final.stdenv) isDarwin;
        inherit (lib.attrsets) optionalAttrs;

        rustPackage =
          (import ./lua-json5.nix {inherit (final) lib rustPlatform pkg-config fetchFromGitHub;}).overrideAttrs
          (optionalAttrs isDarwin {
            # Adding this per the lua-json5 README:
            # https://github.com/Joakker/lua-json5#json5-parser-for-luajit
            CARGO_TARGET_X86_64_APPLE_DARWIN_RUSTFLAGS = "-C link-arg=-undefined -C link-arg=dynamic_lookup";
            CARGO_TARGET_AARCH64_APPLE_DARWIN_RUSTFLAGS = "-C link-arg=-undefined -C link-arg=dynamic_lookup";
          });

        plugin = vimPluginBuilder rustPackage.pname rustPackage.src rustPackage.version;

        pluginWithRustPackage = final.pkgs.symlinkJoin {
          name = plugin.pname;

          paths = [
            rustPackage
            plugin
          ];

          # For this to work on macOS, I have to rename the *.dylib to *.so. Read this thread to
          # learn why:
          # https://github.com/neovim/neovim/issues/21749#issuecomment-1378752957
          #
          # TODO: This should probably be upstreamed.
          postBuild = ''
            cd $out
            mv ./lib/liblua_json5.${
              if isDarwin
              then "dylib"
              else "so"
            } ./lua/json5.so
          '';
        };
      in
        pluginWithRustPackage;

      vimPlugins = prev.vimPlugins // newVimPlugins // {inherit nvim-treesitter lua-json5;};
    in {inherit vimPlugins;};
  in {overlays.vimPlugins = overlay;};
}
