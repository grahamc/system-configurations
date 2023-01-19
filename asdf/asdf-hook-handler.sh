#!/bin/env sh

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

log() {
  printf "\033[01;34m%s\033[0m\n" "$1"
}

error() {
  printf "\033[01;31m%s\033[0m\n" "$1"
}

HOOK_NAME="$1"
case "$HOOK_NAME" in

  # After installing the direnv plugin, run the setup script.
  post_asdf_plugin_add_direnv)
    log "Setting up asdf-direnv..."
    asdf direnv setup --shell fish --version system
    ;;

  # After installing a tool, install the active version of that tool.
  post_asdf_plugin_add)
    TOOL_NAME="$2"
    TOOL_VERSION="$(asdf current "$TOOL_NAME" | awk '{print $2}')"
    # I don't want the script to exit if this command fails, but I also need its exit code so I put it in an if statement.
    if asdf current "$TOOL_NAME" >/dev/null 2>&1; then
      ASDF_CURRENT_EXIT_CODE="$?"
    else
      ASDF_CURRENT_EXIT_CODE="$?"
    fi

    # An exit code of 1 means the active version of the tool is not installed
    if test "$ASDF_CURRENT_EXIT_CODE" -eq 1 && test "$TOOL_VERSION" != 'system'; then
      log "The active version of $TOOL_NAME is not installed. Installing now..."
      if asdf install "$TOOL_NAME"; then
        log "Successfully installed the active version of $TOOL_NAME"
      else
        error "Failed to install the active version of $TOOL_NAME"
      fi
    fi
    ;;

  *)
    error "ERROR: Invalid hook name '$HOOK_NAME'"
    exit 1
    ;;

esac
