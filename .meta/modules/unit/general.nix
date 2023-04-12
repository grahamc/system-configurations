{ config, lib, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeSymlinksToTopLevelFilesInRepo
      ;
  in
    {
      home.file = makeSymlinksToTopLevelFilesInRepo ".local/bin" "general/executables";
    }
