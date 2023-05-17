# This module assigns each host manager (home-manager, nix-darwin, etc.) a list of inputs. These are the
# inputs that the host manager should upgrade as part of `hostctl-upgrade`. This way I don't
# update nix-darwin related inputs while I'm on Linux and risk breaking something I can't test.
{ inputs, ... }:
  {
    flake =
      let
        inherit (inputs.nixpkgs) lib;
        inputListsByHostManager = rec {
          home = [
            "nixpkgs"
            "flake-utils"
            "flake-parts"
            "home-manager"
            "nix-index-database"
            "nix-appimage"
            "vim-plugin-vim-CursorLineCurrentWindow"
            "vim-plugin-virt-column.nvim"
            "vim-plugin-folding-nvim"
            "vim-plugin-cmp-env"
            "vim-plugin-SchemaStore.nvim"
            "vim-plugin-vim"
            "vim-plugin-vim-caser"
            "tmux-plugin-resurrect"
            "tmux-plugin-tmux-suspend"
            "fish-plugin-autopair-fish"
            "fish-plugin-async-prompt"
            "nix-xdg"
          ];
          darwin = home ++ [
            "nix-darwin"
            "stackline"
          ];
        };
        isInputListed = input:
          let
            containsInput = builtins.elem input;
            inputLists = builtins.attrValues inputListsByHostManager;
          in
            builtins.any containsInput inputLists;
        inputNames = (lib.lists.remove "self" (builtins.attrNames inputs));
        unlistedInputs = builtins.filter (input: !(isInputListed input)) inputNames;
        hasAllInputsListed = unlistedInputs == [];
        convertInputListToUpdateFlags = inputList:
          let
            convertInputToUpdateFlag = input: ''--update-input ${lib.strings.escapeShellArgs [input]}'';
            updateFlags = map convertInputToUpdateFlag inputList;
            joinedUpdateFlags = lib.concatStringsSep
              " "
              updateFlags;
          in
            joinedUpdateFlags;
        joinedUnlistedInputs = lib.concatStringsSep ", " unlistedInputs;
        updateFlagsByHostManager = lib.mapAttrs
          (_ignored: inputList: convertInputListToUpdateFlags inputList)
          inputListsByHostManager;
        # I'm converting the inputs to a set of `--update-input <input>` commandline flags so they be passed directly
        # to the host manager's switch command e.g. `home-manager --switch <update_input_flags>`.
        updateFlags = if hasAllInputsListed
          then updateFlagsByHostManager
          else abort "You need to specify when these inputs should be updated: ${joinedUnlistedInputs}";
      in
        {
          lib = {
            inherit updateFlags;
          };
        };
  }
