# shellcheck shell=sh

executable_name="/tmp/bigolu.dotfiles.$$"

# Arrange for the temporary file to be deleted when the script terminates
#
# shellcheck disable=2064
# This check warns that the variables in the string will be substituted now as opposed to when the trap executes.
# This is fine since the variable's value won't change.
#
# shellcheck disable=2154
# This check warns that $answer is referenced, but no assigned. It's not taking into account that I escaped the '$'
# so the variable will be evaluated when the trap executes and an earlier statement in the trap assigns
# the variable $answer.
trap "[ -f $executable_name ] || exit; printf 'Do you want to remove the shell executable \"$executable_name\"? (y/n): '; read -r answer; [ \"\$answer\" = y ] && rm -f $executable_name" 0

trap 'exit $?' 1 2 3 15

curl --fail --progress-bar --location \
  https://github.com/bigolu/dotfiles/releases/download/master/shell \
  --output "$executable_name"

# Make the temporary file executable
chmod +x "$executable_name"

# Execute the temporary file
"$executable_name"
