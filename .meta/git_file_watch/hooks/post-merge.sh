#!/usr/bin/env sh

# Assign stdin, stdout, and stderr to the terminal
exec </dev/tty >/dev/tty 2>&1

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

./.meta/git_file_watch/file_watcher.sh
