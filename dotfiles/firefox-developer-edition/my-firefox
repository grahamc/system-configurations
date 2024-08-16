#!/usr/bin/env sh

# If Firefox Developer Edition is open, use that instead of normal firefox.

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

devedition_executable_name='firefox-devedition'
regular_executable_name='firefox'

if pgrep --full "$devedition_executable_name" >/dev/null 2>&1; then
  exec "$devedition_executable_name" "$@"
else
  exec "$regular_executable_name" "$@"
fi
