# Since many of the files that I link with Home Manager are symlinks, the Home Manager `onChange` hook doesn't
# work for me. Instead, I made this module that lets you run commands when a file changes in git. For example,
# after a `git pull`.
{
  config,
  lib,
  pkgs,
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
    mapOnChangeEntryToScript = onChangeEntry: let
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
      script = ''
        if ${joinedConditions}; then
          ${action}
        fi
      '';
    in
      script;
    # This sorts in increasing order, but I want decreasing order since higher priorities should go first.
    # To reverse the sort order I negate the comparator return value.
    sortedOnChangeEntries =
      lib.lists.sort
      (a: b: !(a.priority < b.priority))
      config.repository.git.onChange;
    onChangeScripts =
      map
      mapOnChangeEntryToScript
      sortedOnChangeEntries;
    joinedOnChangeScripts =
      lib.strings.concatStringsSep
      "\n\n"
      onChangeScripts;
    gitHookDirectory = "${config.repository.directory}/.git/hooks";
    onChangeScript = ''
      ${builtins.readFile ./on-change-base.sh}
      ${joinedOnChangeScripts}
    '';
    # TODO: The indentation in the script isn't consistent.
    # issue: https://github.com/NixOS/nix/issues/543
    makeOnChangeHook = hookBase: ''      #!${pkgs.bash}/bin/bash

                    # Assign stdin, stdout, and stderr to the terminal
                    exec </dev/tty >/dev/tty 2>&1

                    # Exit if a command returns a non-zero exit code
                    set -o errexit

                    # Exit if an unset variable is referenced
                    set -o nounset

                    ${
        if hookBase != null
        then hookBase
        else ""
      }

                    ${onChangeScript}
    '';
    hooks = {
      "${gitHookDirectory}/post-merge" = {
        text = makeOnChangeHook null;
        executable = true;
      };
      "${gitHookDirectory}/post-rewrite" = {
        text =
          makeOnChangeHook
          ''
            if [ "''$1" != 'rebase' ]; then
              exit
            fi
          '';
        executable = true;
      };
    };
  in {
    home.file = hooks;
  };
}
