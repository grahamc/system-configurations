set shell := ["bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

# To handle multiple arguments that each could have spaces:
# https://github.com/casey/just/issues/647#issuecomment-1404056424
set positional-arguments := true

# Display a list of all tasks.
default:
    @just --list --justfile {{ module_file() }} --unsorted

fixup-renovate-pull-request-for-envrc:
    #!/usr/bin/env fish
    set original_envrc "$(cat .envrc)"
    set nix_direnv_url (string match --groups-only --regex --all -- 'source_url [\'"](?<url>https://raw.githubusercontent.com/nix-community/nix-direnv/.*/direnvrc.*)[\'"] [\'"].*[\'"]' "$original_envrc")
    set nix_direnv_hash (direnv fetchurl "$nix_direnv_url")
    set new_envrc "$(string replace --regex -- 'source_url [\'"](?<url>https://raw.githubusercontent.com/nix-community/nix-direnv/.*/direnvrc.*)[\'"] [\'"].*[\'"]' "source_url '$nix_direnv_url' '$nix_direnv_hash'" "$original_envrc")"
    echo "$new_envrc" > .envrc

gomod2nix:
    cd ./flake-modules/bundler/gozip && nix develop github:nix-community/gomod2nix --command gomod2nix generate

test:
    bash tests.bash