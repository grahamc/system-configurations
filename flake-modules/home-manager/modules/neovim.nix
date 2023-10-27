{ pkgs, config, lib, specialArgs, ... }:
  {
    home.packages = with pkgs; [
      neovim-unwrapped
    ];

    repository.symlink.xdg.configFile = {
      "nvim" = {
        source = "neovim";
        recursive = true;
      };
    };

    vimPlug.configDirectory = config.repository.directoryPath + "/dotfiles/neovim/lua"; 
    
    home.file = {
      "${config.repository.directory}/.luarc.json".source =
        let
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
                  # The `grep` command is there to filter out any messages that get printed on startup.
                  ''
                    ${pkgs.neovim-unwrapped}/bin/nvim --headless  -c 'lua for _,directory in ipairs(vim.api.nvim_get_runtime_file("", true)) do print(directory) end' -c 'quit' 2>&1 | tr -d '\r' | grep -E '^/' > $out
                  ''
              )) ;
          workspaceDirectories = [
            "${specialArgs.flakeInputs.neodev-nvim}/types/stable"
            "${config.xdg.dataHome}/nvim/plugged"
            "/Users/biggs/.hammerspoon/Spoons/EmmyLua.spoon/annotations"
          ] ++ runtimeDirectories;
          configAttrs = {
            runtime = {
              version = "LuaJIT";
            };
            workspace = {
              # Make the server aware of Neovim runtime files
              library = workspaceDirectories;
              checkThirdParty = false;
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
