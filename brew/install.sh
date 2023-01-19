#!/bin/sh

# Exit if a command returns a non-zero exit code
set -o errexit

# Exit if an unset variable is referenced
set -o nounset

if ! command -v brew >/dev/null 2>&1; then
  NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Setup brew
#
# DUPLICATE: brew-setup
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Increasing the open file limit since `brew bundle install` usually exceeds the default of 1024.
# NOTE: POSIX shell doesn't support `ulimit -Sn` so to avoid adding a dependency on another shell, like bash, I'm
# doing it in python since I already have python as a dependency. Since the new limit only applies to the current
# process and its children, I need to launch brew from python as well.
python -c 'import resource as res; res.setrlimit(res.RLIMIT_NOFILE, (10000, res.getrlimit(res.RLIMIT_NOFILE)[1])); import subprocess as sp; sp.run(["brew" "bundle" "install" "--no-upgrade" "--file" "./brew/Brewfile"])'
