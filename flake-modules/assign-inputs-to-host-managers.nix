# This module assigns each host manager (home-manager, nix-darwin, etc.) a list of inputs. These are
# the inputs that the host manager should upgrade as part of `hostctl-upgrade`. This way I don't
# update nix-darwin related inputs while I'm on Linux and risk breaking something I can't test.
{inputs, ...}: {
  flake = let
    inherit (inputs.nixpkgs) lib;
    plugins =
      builtins.filter
      (
        inputName:
          (lib.strings.hasPrefix "vim-plugin-" inputName)
          || (lib.strings.hasPrefix "fish-plugin-" inputName)
          || (lib.strings.hasPrefix "tmux-plugin-" inputName)
      )
      (builtins.attrNames inputs);
    # TODO: The inputs lists should probably be maps:
    # - Hosts could override the inclusion of an input by passing `input = false` can't do
    # that with lists.
    # - Each map could specify all of its related inputs and I could merge multiple maps without
    # worrying about duplicates.
    # - Essentially all the benefits I get from the module system in general.
    inputListsByHostManager = rec {
      homeManager =
        [
          "nixpkgs"
          "flake-utils"
          "flake-parts"
          "home-manager"
          "nix-index-database"
          "nix-xdg"
          "gomod2nix"
          "neodev-nvim"
          "wezterm-terminfo"
          "tmux"
          "neovim-nightly-overlay"
          "wezterm"
        ]
        ++ plugins;
      nixDarwin =
        homeManager
        ++ [
          "nix-darwin"
          "stackline"
          "spoons"
          "nixpkgs-for-wezterm-darwin"
        ];
      portableHomeLinux = [
        "nixgl"
      ];
    };
    uniqueAssignments = lib.lists.unique (lib.lists.flatten (builtins.attrValues inputListsByHostManager));
    flakeInputNames = lib.lists.remove "self" (builtins.attrNames inputs);
    intersection = lib.lists.intersectLists uniqueAssignments flakeInputNames;
    intersectionLength = builtins.length intersection;
    isAssignmentsSameAsFlakeInputs =
      ((builtins.length uniqueAssignments) == intersectionLength)
      && ((builtins.length flakeInputNames) == intersectionLength);
    getExclusive = list: let
      joined = lib.concatStringsSep ", " (lib.lists.subtractLists intersection list);
    in
      if joined == ""
      then "<none>"
      else joined;
    exclusiveAssignments = getExclusive uniqueAssignments;
    exclusiveFlakeInputs = getExclusive flakeInputNames;

    convertInputListToUpdateFlags = inputList: let
      convertInputToUpdateFlag = input: ''--update-input ${lib.strings.escapeShellArgs [input]}'';
      updateFlags = map convertInputToUpdateFlag inputList;
      joinedUpdateFlags =
        lib.concatStringsSep
        " "
        updateFlags;
    in
      joinedUpdateFlags;
    updateFlagsByHostManager =
      lib.mapAttrs
      (_ignored: convertInputListToUpdateFlags)
      inputListsByHostManager;
    # I'm converting the inputs to a set of `--update-input <input>` commandline flags so they
    # be passed directly to the host manager's switch command e.g.
    # `home-manager --switch <update_input_flags>`.
    updateFlags =
      if isAssignmentsSameAsFlakeInputs
      then updateFlagsByHostManager
      else abort "The set of inputs assigned to host managers is not the same as the set of flake inputs. Exclusive flake inputs: ${exclusiveFlakeInputs}. Exclusive assignments: ${exclusiveAssignments}";
  in {
    lib = {
      inherit updateFlags;
    };
  };
}
