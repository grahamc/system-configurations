#!/usr/bin/env bash

# shellcheck disable=1090
source <(direnv stdlib)

# load devShell from flake and make it a GC root
if ! has nix_direnv_version || ! nix_direnv_version 3.0.4; then
  source_url \
    "https://raw.githubusercontent.com/nix-community/nix-direnv/3.0.4/direnvrc" \
    "sha256-DzlYZ33mWF/Gs8DDeyjr8mnVmQGx7ASYqA5WlxwvBG4="
fi
use flake

# Get firstaide and add it to the PATH
#
# Put this towards the bottom so if 3rd party scripts add this bin to the PATH, we won't duplicate
# it
platform="$(uname -m)-$(uname -s | tr '[:upper:]' '[:lower:]')"
release_artifact_url="https://github.com/bigolu/dotfiles/releases/download/master/firstaide-master-$platform"
if uname | grep -q Linux; then
  hash='sha256-+c7mTicwOXJxGjViKHkCAf3ZdOPKBCtyHa1bUlcbHws='
else
  hash='sha256-qhro3qVo2urW01OHVKpOUEpZ5WEOr9G65zRAWnrjFwo='
fi
firstaide_path="$(fetchurl "$release_artifact_url" "$hash")"
layout_dir=$(direnv_layout_dir)
if [[ ! -d "$layout_dir/bin" ]]; then
  mkdir -p "$layout_dir/bin"
fi
cp -f "$firstaide_path" "$layout_dir/bin/firstaide"
PATH_rm "$layout_dir/bin"
PATH_add "$layout_dir/bin"

# I want to use my nix wrapper so I need to prepend my bin after the flake bin is added.
PATH_rm ~/.local/bin
PATH_add ~/.local/bin

# secrets
yellow='\e[33m'
reset='\e[m'
function get_secret {
  path="./secrets/$1"

  if [ -f "$path" ]; then
    cat "$path"
  else
    echo -e "[${yellow}warning${reset}] secret '$path' was not found" 1>&2
    return 1
  fi
}
if github="$(get_secret 'github.txt')"; then
  export NIX_CONFIG="access-tokens = github.com=$github"
fi
if bws="$(get_secret 'bws.txt')"; then
  export BWS_ACCESS_TOKEN="$bws"
fi

# call firstaide
eval "$(printf '%q ' "$@")"
