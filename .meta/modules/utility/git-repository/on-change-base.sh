# shellcheck shell=sh

# Contains each added/deleted/changed file. Each file is on its own line.
#
# Format:
# <status letter>    <filename relative to root of repo>
#
# For example, if the Brewfile was modified, this line would be present:
# M    brew/Brewfile
changed_filenames_with_status="$(git diff-tree -r --name-status ORIG_HEAD HEAD)"

# Exits with 0 if the specified file was added, deleted, or modified.
modified() {
  echo "$changed_filenames_with_status" | grep --extended-regexp --quiet "$1"
}

added() {
  echo "$changed_filenames_with_status" | grep --extended-regexp "^A" | grep --extended-regexp --quiet "$1"
}

deleted() {
  echo "$changed_filenames_with_status" | grep --extended-regexp "^D" | grep --extended-regexp --quiet "$1"
}

confirm() {
  printf "%s (y/n): " "$1"
  read -r answer
  [ "$answer" = 'y' ]
}

blue='\e[34m'
reset='\e[0m'
banner_messsage='POST MERGE HOOK'
banner_underline="$(printf %40s '' | sed 's/ /─/g')"
printf "%b\n%s\n%s\n%b" "$blue" "$banner_messsage" "$banner_underline" "$reset"
printf "Checking to see if any actions should be taken as a result of the merge:\n\n"
