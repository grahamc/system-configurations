{ config, lib, pkgs, ... }:
  let
    inherit (lib) types;
    fileChangeType = lib.mkOption {
      type = types.listOf types.str;
      default = [];
    };
    onChangeHandlerType = types.submodule {
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
  in
    {
      options.gitRepository = {
        repositoryPath = lib.mkOption {
          type = types.str;
        };
        onChangeHandlers = lib.mkOption {
          type = types.listOf onChangeHandlerType;
          default = [];
        };
      };

      config =
        let
          makeHandlerString = onChangeHandler:
            let
              # changeType is the name of a function in the script
              makeIfConditionForChangeTypeAndPattern = changeType: pattern: "${changeType} ${lib.strings.escapeShellArgs [pattern]}";
              changeTypes = builtins.attrNames onChangeHandler.patterns;
              conditonsPerChangeType = map
                (changeType:
                  let
                    patterns = onChangeHandler.patterns.${changeType};
                    makeIfConditionForPattern = makeIfConditionForChangeTypeAndPattern changeType;
                    conditions = map makeIfConditionForPattern patterns;
                  in
                    conditions
                )
                changeTypes;
              flattenedConditions = lib.lists.flatten conditonsPerChangeType;
              joinedConditions = lib.strings.concatStringsSep " || " flattenedConditions;
              action = if onChangeHandler.confirmation == null
                then onChangeHandler.action
                else ''
                  if confirm ${lib.strings.escapeShellArgs [onChangeHandler.confirmation]}; then
                    ${onChangeHandler.action}
                  fi
                '';
              handlerString = ''
                if ${joinedConditions}; then
                  ${action}
                fi
              '';
            in
              handlerString;
          # This sorts in increasing order, but I want decreasing order since higher priorities should go first.
          # To reverse the sort order I negate the comparator return value.
          sortedHandlers = lib.lists.sort
            (a: b: !(a.priority < b.priority))
            config.gitRepository.onChangeHandlers;
          handlerStrings = map
            makeHandlerString
            sortedHandlers;
          joinedHandlerStrings = lib.strings.concatStringsSep
            "\n\n"
            handlerStrings;
          onChangeScript = ''
            ${builtins.readFile ./on-change-base.sh}
            ${joinedHandlerStrings}
          '';
          # TODO: The indentation in the script isn't consistent.
          # issue: https://github.com/NixOS/nix/issues/543
          makeOnChangeHook = hookBasePath:
            ''#!${pkgs.dash}/bin/dash
              
              # Assign stdin, stdout, and stderr to the terminal
              exec </dev/tty >/dev/tty 2>&1

              # Exit if a command returns a non-zero exit code
              set -o errexit

              # Exit if an unset variable is referenced
              set -o nounset

              ${if hookBasePath != null then builtins.readFile hookBasePath else ""}

              ${onChangeScript}
            '';
          postMergeHook = makeOnChangeHook null;
          postRewriteHook = makeOnChangeHook ./post-rewrite-hook-base.sh;
        in
          {
            home.file = {
              "${config.gitRepository.repositoryPath}/.git/hooks/post-merge" = {
                text = postMergeHook;
                executable = true;
              };
              "${config.gitRepository.repositoryPath}/.git/hooks/post-rewrite" = {
                text = postRewriteHook;
                executable = true;
              };
            };
          };
    }
