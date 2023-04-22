{ config, lib, specialArgs, ... }:
  let
    inherit (import ../util.nix {inherit config lib specialArgs;})
      makeSymlinksToTopLevelFilesInRepo
      ;
  in
    {
      home.file = makeSymlinksToTopLevelFilesInRepo ".local/bin" "general/executables" ../../../general/executables;
    }
