set shell := ["bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

# To handle multiple arguments that each could have spaces:
# https://github.com/casey/just/issues/647#issuecomment-1404056424
set positional-arguments := true

# Tasks run during continuous integration (CI)
mod ci

# Display a list of all tasks.
default:
    @just --list --justfile {{ module_file() }} --unsorted

# Reload direnv
reload-dev-environment:
    nix-direnv-reload

# Switch to a new generation
switch:
    hostctl-switch

# Update flake inputs and switch to a new generation
upgrade:
    hostctl-upgrade

# Preview changes from switching
preview-switch:
    hostctl-preview-switch

# Rerun the on change actions that run after a git merge or rebase
run-on-change-actions:
    bash ./.git-hook-assets/on-change.bash

test:
    bash tests.bash

get-secrets:
    #!/usr/bin/env bash
    set -o errexit
    set -o nounset
    set -o pipefail

    project_dir="$PWD"

    temp="$(mktemp --directory)"
    trap 'rm -rf $temp' SIGINT SIGTERM ERR EXIT
    cd $temp

    if test -z "${BWS_ACCESS_TOKEN:-}"; then
        printf 'Enter the service account token (or just press enter to cancel):'
        read -rs token
        test -z "$token" && exit
        export BWS_ACCESS_TOKEN="$token"
    fi

    bws="$(NIXPKGS_ALLOW_UNFREE=1 nix shell --impure nixpkgs#bws --command which -- bws)"
    PATH="$(dirname "$bws"):$PATH"

    declare -A secrets_to_fetch=(
        ['917561bd-57d8-4009-8155-b0f9016c89a2']="$project_dir/secrets/bws.txt"
        ['b2fe18ea-c96b-48e6-ae20-b0f90159d299']="$project_dir/secrets/github.txt"
        ['a45acbd3-45ac-43f1-96fd-b0f9015b6c2c']="$HOME/.cloudflared/a52a24f6-92ee-4dc5-b537-24bad84b7b1f.json"
    )
    declare -A secrets_to_commit
    for bws_id in "${!secrets_to_fetch[@]}"; do
        destination="${secrets_to_fetch[$bws_id]}"
        temp_filename="$(printf "$destination" | tr '/' '%')"
        printf "$(bws secret get "$bws_id" | jq --raw-output '.value')" > "$temp_filename"
        secrets_to_commit["$temp_filename"]="$destination"
    done

    # Writing secrets now to ensure we only write secrets if we succeed in
    # getting all of them
    for temp_filename in "${!secrets_to_commit[@]}"; do
        destination="${secrets_to_commit[$temp_filename]}"
        mkdir -p "$(dirname "$destination")"
        mv "$temp_filename" "$destination"
    done

gomod2nix:
    cd ./flake-modules/bundler/gozip && nix develop github:nix-community/gomod2nix --command gomod2nix generate

go-mod-tidy:
    cd ./flake-modules/bundler/gozip && go mod tidy

format *FILES:
    #!/usr/bin/env fish

    if test (count $argv) -eq 0
        treefmt --no-cache
    else
        # TODO: The output of `treefmt --help` says you can pass in multiple
        # paths, but it doesn't work
        for file in $argv
            treefmt --no-cache "$file"
        end
    end

[private]
lint *FILES:
    #!/usr/bin/env fish

    set files $argv

    if test (count $files) -eq 0
        set lint_everything 1
    end

    function filter --argument-names pattern
        string match --all --entire --regex "$pattern" $files
    end

    if test -n "$lint_everything"
        renovate-config-validator --strict
    else
        set matches (filter 'renovate\.json5$')
        if test (count $matches) -gt 0
            renovate-config-validator --strict $matches
        end
    end

    if test -n "$lint_everything"
        statix check ./
    else
        # statix doesn't support passing multiple files yet:
        # https://github.com/nerdypepper/statix/issues/69
        for file in (filter '.*\.nix$')
            statix check "$file"
        end
    end

    if test -n "$lint_everything"
        actionlint
    else
        set matches (filter '.github/workflows/.*\.yml$')
        if test (count $matches) -gt 0
            actionlint $matches
        end
    end

# Install git hooks
[private]
install-git-hooks:
    lefthook install --force

# I'm not able to upgrade the nix and cacert that come with the nix installation
# using `nix profile upgrade '.*'` so here I'm installing them from the nixpkgs

# flake and giving them priority.
[private]
base-packages:
    sudo --set-home --preserve-env=PATH env nix profile install nixpkgs#nix --priority 4
    sudo --set-home --preserve-env=PATH env nix profile install nixpkgs#cacert --priority 4

# home-manager can't run these since they require root privileges
[private]
linux-root-scripts:
    #!/usr/bin/env bash
    set -o errexit
    set -o nounset
    set -o pipefail

    ./dotfiles/nix/set-locale-variable.bash
    ./dotfiles/nix/nix-fix/install-nix-fix.bash
    ./dotfiles/nix/systemd-garbage-collection/install.bash
    ./dotfiles/smart_plug/linux/install.bash
    ./dotfiles/linux/set-keyboard-to-mac-mode.sh
    ./dotfiles/keyd/install.bash
    ./dotfiles/firefox-developer-edition/set-default-browser.sh

# Apply the first generation of a home-manager configuration.
[private]
init-home-manager host_name: install-git-hooks get-secrets base-packages && linux-root-scripts
    nix run .#nix -- run .#homeManager -- switch --flake .#{{ host_name }}

[private]
brew:
    #!/usr/bin/env bash
    set -o errexit
    set -o nounset
    set -o pipefail

    if [ -x /usr/local/bin/brew ]; then
        exit
    fi

    # Install brew. Source: https://brew.sh/
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Apply the first generation of a nix-darwin configuration.
[private]
init-nix-darwin host_name: install-git-hooks get-secrets base-packages brew
    nix run .#nix -- run .#nixDarwin -- switch --flake .#{{ host_name }}

# Generate the Table of Contents in the README
[private]
generate-readme-table-of-contents:
    doctoc README.md --github

# Generate a file with a list of all my neovim plugins
[private]
generate-neovim-plugin-list:
    #!/usr/bin/env bash
    set -euo pipefail

    readarray -t config_files < <(find ./dotfiles/neovim/lua -type f -name '*.lua')
    sg --lang lua --pattern 'Plug($ARG $$$)' --json=compact "${config_files[@]}" | jq --raw-output '.[].metaVariables.single.ARG.text' \
    | cut -d'/' -f2 | sed 's/.$//' | sort --ignore-case --dictionary-order --unique > ./dotfiles/neovim/plugin-names.txt
