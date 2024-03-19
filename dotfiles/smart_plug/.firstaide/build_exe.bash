#!/usr/bin/env bash

# shellcheck disable=1090
source <(direnv stdlib)

platform="$(uname -m)-$(uname -s | tr '[:upper:]' '[:lower:]')"
release_artifact_url="https://github.com/bigolu/dotfiles/releases/download/master/firstaide-master-$platform"
if uname | grep -q Linux; then
  hash='sha256-4vQQscdoRI9XbCF5fAMhTgSPPuXFu5NEw5feoyjq8MU='
else
  hash='sha256-67wqDatM7CAusOiJhX2oMiJXOfVseXtN6JDtHWYZgnU='
fi
firstaide_path="$(fetchurl "$release_artifact_url" "$hash")"
layout_dir=$(direnv_layout_dir)
if [[ ! -d "$layout_dir/bin" ]]; then
  mkdir -p "$layout_dir/bin"
fi
ln -s "$firstaide_path" "$layout_dir/bin/firstaide"
PATH_rm "$layout_dir/bin"
PATH_add "$layout_dir/bin"

# load devShell from flake and make it a GC root
if ! has nix_direnv_version || ! nix_direnv_version 3.0.4; then
  source_url \
    "https://raw.githubusercontent.com/nix-community/nix-direnv/3.0.4/direnvrc" \
    "sha256-DzlYZ33mWF/Gs8DDeyjr8mnVmQGx7ASYqA5WlxwvBG4="
fi
use flake '../../#smartPlug'

# So debugpy can find the right python to use. The 2 dirnames remove '/bin/python' so we end up with
# the python installation folder.
VIRTUAL_ENV="$(dirname "$( dirname "$(realpath --canonicalize-existing "$(which python)")" )")"
export VIRTUAL_ENV

# call firstaide
eval "$(printf '%q ' "$@")"
