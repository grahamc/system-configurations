#!/bin/env sh

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

print_help_text() {
  cat << END_OF_STRING
dotfiles.sh
A CLI for managing dotfiles.

To set the active profile:
  dotfiles.sh profile

To install the active profile:
  dotfiles.sh install

To install one or more modules:
  dotfiles.sh module [<module_name>...]
  For example: dotfiles.sh module ripgrep neovim

To get this message:
  dotfiles.sh
END_OF_STRING
}

if [ $# -eq 0 ]; then
  print_help_text
  exit
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT_DIR="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel)"
ACTIVE_PROFILE_PATH="${REPO_ROOT_DIR}/.active-profile"

case "$1" in
  profile)
    printf "Choose a profile from this list: \n%s\nInput: " "$(find "${REPO_ROOT_DIR}/meta/profiles" -print0 | xargs -0 -I FILENAME basename FILENAME .txt)"
    while
      profile_name="$(read -r NAME; printf %s "$NAME")"
      ! [ -f "${REPO_ROOT_DIR}/meta/profiles/${profile_name}.txt" ]
    do printf 'ERROR: Invalid profile name, try again: ' >&2;  done

    ln --force --symbolic "${REPO_ROOT_DIR}/meta/profiles/${profile_name}.txt" "$ACTIVE_PROFILE_PATH"
    ;;

  install)
    if [ $# -eq 0 ]; then
      if ! [ -f "$ACTIVE_PROFILE_PATH" ]; then
        # shellcheck disable=2016
        # I don't want to expand the text in backticks
        echo 'ERROR: No active profile found, set one with `dotfiles.sh profile`' >&2
        exit 1
      fi

      profile_path="$(readlink "$ACTIVE_PROFILE_PATH")"
      "${REPO_ROOT_DIR}/meta/install-profile.bash" "$(basename "$profile_path" .txt)"
    else
      "${REPO_ROOT_DIR}/meta/install-module.bash" "$@"
    fi
    ;;

  *)
    echo 'ERROR: Unknown command' >&2
    exit 1
    ;;
esac
