{ config, lib, ... }:
  let
    inherit (import ../util.nix {inherit config lib;})
      makeOutOfStoreSymlinksForTopLevelFiles
      ;
  in
    {
      home.file = makeOutOfStoreSymlinksForTopLevelFiles ".local/bin" "general/executables";
    }
