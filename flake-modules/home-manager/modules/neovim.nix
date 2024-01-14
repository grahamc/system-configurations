{
  pkgs,
  config,
  lib,
  specialArgs,
  ...
}: {
  home = {
    packages = with pkgs; [
      neovim-unwrapped
      # TODO: Text will be lost on reflow until this issue is resolved:
      # https://github.com/neovim/neovim/issues/2514
      page
    ];

    # TODO: vim.loader() uses modification time and file size as a cache key. This is a problem for the plugin
    # sqlite.lua because in one of its files (defs.lua) has the path to sqlite which changes when I upgrade sqlite.
    # The problem is that nix sets the modification time to the epoch for all files and the size will be the same
    # because (I think) the hashes that nix generates for package paths are all the same length, only the letters in
    # the hash change. This means when I start vim after sqlite has been upgraded, sqlite.lua won't be able to find
    # sqlite (assuming the old version has been garbage collected already) because neovim is still using the stale,
    # cached bytecode for defs.lua which contains the old path to sqlite.
    activation.vimLoaderFix =
      lib.hm.dag.entryAfter
      ["writeBoundary"]
      ''
        ${pkgs.neovim-unwrapped}/bin/nvim --clean --headless -c 'lua vim.loader.reset()' -c 'quit'
      '';

    file = {
      "${config.repository.directory}/.luarc.json".source =
        pkgs.runCommand
        "runtime-directories.txt"
        {nativeBuildInputs = with pkgs; [neovim-unwrapped jq];}
        ''
          # Read this to see why the `tr` command is needed:
          # https://stackoverflow.com/questions/16739300/redirect-ex-command-to-stdout-in-vim
          #
          # The command is there to filter out any messages that get printed on startup.
          # I'm redirecting stderr to stdout because neovim prints its output on stderr.
          readarray -t runtime_dirs < <(nvim --headless  -c 'lua for _,directory in ipairs(vim.api.nvim_get_runtime_file("", true)) do print(directory) end' -c 'quit' 2>&1 | tr -d '\r' | grep -E '^/')
          jq \
            --null-input \
            '{"$schema": "https://raw.githubusercontent.com/sumneko/vscode-lua/master/setting/schema.json", "workspace": {"library": $ARGS.positional, "checkThirdParty": "Disable"}, "runtime": {"version": "LuaJIT"}, "telemetry": {"enable": false}}' \
            --args \
              '${specialArgs.flakeInputs.neodev-nvim}/types/stable' \
              '${config.xdg.dataHome}/nvim/plugged' \
              '${specialArgs.homeDirectory}/.hammerspoon/Spoons/EmmyLua.spoon/annotations' \
              "''${runtime_dirs[@]}" \
            > $out
        '';
    };
  };

  repository.symlink.xdg.configFile = {
    "nvim" = {
      source = "neovim";
      recursive = true;
    };
  };

  vimPlug.pluginFile = config.repository.directoryPath + "/dotfiles/neovim/plugin-names.txt";
}
