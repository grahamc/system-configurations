{
  pkgs,
  config,
  lib,
  specialArgs,
  ...
}: {
  home.packages = with pkgs; [
    neovim-unwrapped
    # TODO: Text will be lost on reflow until this issue is resolved:
    # https://github.com/neovim/neovim/issues/2514
    page
  ];

  repository.symlink.xdg.configFile = {
    "nvim" = {
      source = "neovim";
      recursive = true;
    };
  };

  vimPlug.configDirectory = config.repository.directoryPath + "/dotfiles/neovim/lua";

  # TODO: vim.loader() uses modification time and file size as a cache key. This is a problem for the plugin
  # sqlite.lua because in one of its files (defs.lua) has the path to sqlite which changes when I upgrade sqlite.
  # The problem is that nix sets the modification time to the epoch for all files and the size will be the same
  # because (I think) the hashes that nix generates for package paths are all the same length, only the letters in
  # the hash change. This means when I start vim after sqlite has been upgraded, sqlite.lua won't be able to find
  # sqlite (assuming the old version has been garbage collected already) because neovim is still using the stale,
  # cached bytecode for defs.lua which contains the old path to sqlite.
  home.activation.vimLoaderFix =
    lib.hm.dag.entryAfter
    ["writeBoundary"]
    # Read this to see why the `tr` command is needed:
    # https://stackoverflow.com/questions/16739300/redirect-ex-command-to-stdout-in-vim
    #
    # The `grep` command is there to filter out any messages that get printed on startup.
    # I'm redirecting stderr to stdout because neovim prints its output on stderr.
    # The '*' is outside the string so bash will use it as a regex matcher and not a literal '*'.
    ''
      rm -rf "''$(${pkgs.neovim-unwrapped}/bin/nvim --headless -c 'lua= vim.fn.stdpath("cache")' -c 'quit' 2>&1 | tr -d '\r' | grep -E '^/')/luac/"*
    '';

  home.file = {
    "${config.repository.directory}/.luarc.json".source = let
      runtimeDirectories =
        lib.strings.splitString
        "\n"
        (builtins.readFile (
          pkgs.runCommand
          "runtime-directories.txt"
          {}
          # Read this to see why the `tr` command is needed:
          # https://stackoverflow.com/questions/16739300/redirect-ex-command-to-stdout-in-vim
          #
          # The command is there to filter out any messages that get printed on startup.
          # I'm redirecting stderr to stdout because neovim prints its output on stderr.
          ''
            ${pkgs.neovim-unwrapped}/bin/nvim --headless  -c 'lua for _,directory in ipairs(vim.api.nvim_get_runtime_file("", true)) do print(directory) end' -c 'quit' 2>&1 | tr -d '\r' | grep -E '^/' > $out
          ''
        ));
      workspaceDirectories =
        [
          "${specialArgs.flakeInputs.neodev-nvim}/types/stable"
          "${config.xdg.dataHome}/nvim/plugged"
          "${specialArgs.homeDirectory}/.hammerspoon/Spoons/EmmyLua.spoon/annotations"
        ]
        ++ runtimeDirectories;
      configAttrs = {
        "$schema" = "https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json";
        runtime = {
          version = "LuaJIT";
        };
        workspace = {
          # Make the server aware of Neovim runtime files
          library = workspaceDirectories;
          checkThirdParty = "Disable";
        };
        telemetry = {
          # Do not send telemetry data containing a randomized but unique identifier
          enable = false;
        };
      };
      luarc = pkgs.writeText ".luarc.json" (builtins.toJSON configAttrs);
    in
      luarc;
  };
}
