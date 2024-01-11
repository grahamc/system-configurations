# Since many of the files that I link with Home Manager are symlinks, the Home Manager `onChange` hook doesn't
# work for me. Instead, I made this module that lets you run commands when a file changes in git. For example,
# after a `git pull`.
{
  config,
  lib,
  ...
}: let
  inherit (lib) types;
  fileChangeType = lib.mkOption {
    type = types.listOf types.str;
    default = [];
  };
  onChangeType = types.submodule {
    options = {
      patterns = {
        modified = fileChangeType;
        added = fileChangeType;
        deleted = fileChangeType;
      };
      action = lib.mkOption {
        type = types.str;
      };
      confirmation = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      priority = lib.mkOption {
        type = types.ints.between 0 100;
        default = 50;
      };
    };
  };
in {
  options.repository.git = {
    onChange = lib.mkOption {
      type = types.listOf onChangeType;
      default = [];
    };
  };

  config = let
    mapOnChangeEntryToSnippet = onChangeEntry: let
      # changeType is the name of a function in the script
      makeIfConditionForChangeTypeAndPattern = changeType: pattern: "${changeType} ${lib.strings.escapeShellArgs [pattern]}";
      changeTypes = builtins.attrNames onChangeEntry.patterns;
      conditonsPerChangeType =
        map
        (
          changeType: let
            patterns = onChangeEntry.patterns.${changeType};
            makeIfConditionForPattern = makeIfConditionForChangeTypeAndPattern changeType;
            conditions = map makeIfConditionForPattern patterns;
          in
            conditions
        )
        changeTypes;
      flattenedConditions = lib.lists.flatten conditonsPerChangeType;
      joinedConditions = lib.strings.concatStringsSep " || " flattenedConditions;
      action =
        if onChangeEntry.confirmation == null
        then onChangeEntry.action
        else ''
          if confirm ${lib.strings.escapeShellArgs [onChangeEntry.confirmation]}; then
            ${onChangeEntry.action}
          fi
        '';
      snippet = ''
        if ${joinedConditions}; then
          ${action}
        fi
      '';
    in
      snippet;

    # This sorts in increasing order, but I want decreasing order since higher priorities should go first.
    # To reverse the sort order I negate the comparator return value.
    sortedOnChangeEntries =
      lib.lists.sort
      (a: b: !(a.priority < b.priority))
      config.repository.git.onChange;

    snippets = map mapOnChangeEntryToSnippet sortedOnChangeEntries;

    mapWithIndex = function: list: let
      inherit (lib.lists) range zipLists;
      indices = range 1 (builtins.length list);
      zippedList = zipLists list indices;
      zippedListRenamed =
        map (x: {
          item = x.fst;
          index = x.snd;
        })
        zippedList;
    in
      map function zippedListRenamed;

    onChangeFiles =
      builtins.listToAttrs
      (
        mapWithIndex
        (
          {
            item,
            index,
          }: {
            name = "${config.repository.directory}/.git-hook-assets/actions/${toString index}";
            value = {text = item;};
          }
        )
        snippets
      );
  in {
    home.file = onChangeFiles;
  };
}
