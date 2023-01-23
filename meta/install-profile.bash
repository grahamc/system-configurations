#!/usr/bin/env bash

set -e

BASE_CONFIG="base"
CONFIG_SUFFIX=".yaml"

META_DIR="meta"
MODULES_DIR="modules"
PROFILES_DIR="profiles"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT_DIR="$(cd "$BASE_DIR" && git rev-parse --show-toplevel)"

cd "${BASE_DIR}"

pip_command="$(command -v pip3 >/dev/null 2>&1 && printf pip3 || printf pip)"
if ! command -v dotbot >/dev/null 2>&1; then
  "$pip_command" install dotbot
fi

while IFS= read -r config; do
  CONFIGS+=" ${config}"
done < "${REPO_ROOT_DIR}/${META_DIR}/${PROFILES_DIR}/${1}.txt"

shift

for config in ${CONFIGS} "${@}"; do
  echo -e "\nConfigure $config"
  # create temporary file
  configFile="$(mktemp)"
  suffix="-sudo"
  echo -e "$(<"${BASE_DIR}/${BASE_CONFIG}${CONFIG_SUFFIX}")\n$(<"${BASE_DIR}/${MODULES_DIR}/${config%"$suffix"}${CONFIG_SUFFIX}")" > "$configFile"

  cmd=(dotbot -d "${REPO_ROOT_DIR}" -c "$configFile" -q)

  if [[ $config == *"sudo"* ]]; then
    cmd=(sudo "${cmd[@]}")
  fi

  # Setup brew
  #
  # DUPLICATE: brew-setup
  brew_executable="/home/linuxbrew/.linuxbrew/bin/brew"
  if [ -e "$brew_executable" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi

  # Setup nix
  #
  # DUPLICATE: nix-setup
  _nix_profile_setup_script="$HOME/.nix-profile/etc/profile.d/nix.sh"
  if [ -e "$_nix_profile_setup_script" ]; then
    . "$_nix_profile_setup_script"
  fi

  # The shell commands that I run with Dotbot are in POSIX shell so I need to set my $SHELL to it.
  SHELL="$(command -v sh)" "${cmd[@]}"
  rm -f "$configFile"
done

cd "${BASE_DIR}"
