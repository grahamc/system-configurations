#!/bin/sh

# Assign stdin, stdout, and stderr to the terminal
exec </dev/tty >/dev/tty 2>&1

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

# Contains each added/deleted/changed file. Each file is on its own line.
#
# Format:
# <status letter>    <filename relative to root of repo>
#
# For example, if the Brewfile was modified, this line would be present:
# M    brew/Brewfile
changed_filenames_with_status="$(git diff-tree -r --name-status ORIG_HEAD HEAD)"

# Exits with 0 if the specified file was added, deleted, or modified.
has_changes() {
  echo "$changed_filenames_with_status" | grep --extended-regexp --quiet "$1"
}

has_added_file() {
  echo "$changed_filenames_with_status" | grep --extended-regexp --quiet "^A"
}

has_deleted_file() {
  echo "$changed_filenames_with_status" | grep --extended-regexp --quiet "^D"
}

confirm() {
  printf "%s (y/n): " "$1"
  read -r answer
  [ "$answer" = 'y' ]
}

# With this, even if a command fails the script will continue
suppress_error() {
  "$@" || true
}

blue='\e[34m'
reset='\e[0m'
banner_messsage='POST MERGE HOOK'
banner_underline="$(printf %40s '' | sed 's/ /─/g')"
printf "%b\n%s\n%s\n%b" "$blue" "$banner_messsage" "$banner_underline" "$reset"
printf "Checking to see if any actions should be taken as a result of the merge:\n\n"

# This should be the first check since other checks might depend on new files
# being linked, or removed files being unlinked, in order to work. For example, if a new
# bat theme is added, the theme needs to be linked before we can rebuild the bat cache.
home-manager switch --flake ".#$HOME_MANAGER_HOST_NAME" --impure

# Sorting the files will allow me to control the order that the watches get run in.
# For example, I can prefix a script with '00-' to make sure it gets run first.
for watch in $(find -L ./.meta/git_file_watch/active_file_watches -type f | sort); do
  # shellcheck disable=1090
  . "$watch"
done
