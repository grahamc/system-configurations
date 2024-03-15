set -o errexit
set -o nounset
set -o pipefail

# Assign stdin, stdout, and stderr to the terminal
exec </dev/tty >/dev/tty 2>&1

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
  echo "$changed_filenames_with_status" | sed -E "s/[ADM]\s+//" | grep -q -E "$1"
}

added() {
  echo "$changed_filenames_with_status" | grep -E "^A" | sed -E "s/A\s+//" | grep -q -E "$1"
}

deleted() {
  echo "$changed_filenames_with_status" | grep -E "^D" | sed -E "s/D\s+//" | grep -q -E "$1"
}

# source: https://unix.stackexchange.com/a/464963
read_one_character() { # arg: <variable-name>
  if [ -t 0 ]; then
    # if stdin is a tty device, put it out of icanon, set min and
    # time to sane value, but don't otherwise touch other input or
    # or local settings (echo, isig, icrnl...). Take a backup of the
    # previous settings beforehand.
    saved_tty_settings=$(stty -g)
    stty -icanon min 1 time 0
  fi
  eval "$1="
  while
    # read one byte, using a work around for the fact that command
    # substitution strips trailing newline characters.
    c=$(
      dd bs=1 count=1 2>/dev/null
      echo .
    )
    c=${c%.}

    # break out of the loop on empty input (eof) or if a full character
    # has been accumulated in the output variable (using "wc -m" to count
    # the number of characters).
    [ -n "$c" ] &&
      eval "$1=\${$1}"'$c
          [ "$(($(printf %s "${'"$1"'}" | wc -m)))" -eq 0 ]'
  do
    continue
  done
  if [ -t 0 ]; then
    # restore settings saved earlier if stdin is a tty device.
    #
    # HACK: suppressing the error message:
    # `stty: 'standard input': unable to perform all requested operations`
    stty "$saved_tty_settings" 2>/dev/null
  fi

  # To end the prompt line
  echo
}

confirm() {
  printf "%s (y/n): " "$1"
  read_one_character answer
  # `answer` is set inside of `read_one`
  # shellcheck disable=2154
  [ "$answer" = 'y' ]
}

blue='\e[34m'
reset='\e[0m'
banner_messsage='ON-CHANGE HOOK'
banner_underline="$(printf %40s '' | sed 's/ /─/g')"
printf "%b\n%s\n%s\n%b" "$blue" "$banner_messsage" "$banner_underline" "$reset"
if ! confirm 'Would you like to run the on-change hook?'; then
  exit 0
fi

# Sorting the files will allow me to control the order that the actions get run in.
# For example, I can prefix a script with '00-' to make sure it gets run first.
for action in $(find -L ./.git-hook-assets/actions -type f | sort); do
  # shellcheck disable=1090
  source "$action"
done
