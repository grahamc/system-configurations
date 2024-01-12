set shell := ["bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

# Choose a task. Only includes tasks that don't take arguments.
default:
    @just --choose --unsorted

# Display a list of all tasks.
help:
    @just --list --justfile {{ justfile() }} --unsorted

# Reload direnv
reload:
    nix-direnv-reload

# Switch to a new generation
switch:
    hostctl-switch

# Update flake inputs and switch to a new generation
upgrade: pull && commit
    # We pull first because otherwise tools might try to perform upgrades
    # that have already been performed on another machine and just need to be pulled in.
    # And if upgrading a tool results in a dotfile being changed, (e.g. Nix flake.lock)
    # then pulling dotfiles afterwards might cause a merge conflict.
    hostctl-upgrade

# Preview changes from switching
preview-switch:
    hostctl-preview-switch

# Preview changes from upgrading
preview-upgrade:
    hostctl-preview-upgrade

# Format all source code
format:
    treefmt

# Rerun the on change actions that run after a git merge or rebase
run-on-change-actions:
    bash ./.git-hook-assets/on-change.bash

# Install git hooks
install-git-hooks:
    lefthook install

# Run all tests
test:
  #!/usr/bin/env bash
  set -euo pipefail

  # verify flake output format and build packages
  nix flake check

  # build devShells
  nix flake show --json \
    | jq  ".devShells.\"$(nix show-config system)\"|keys[]" \
    | xargs -I {} nix develop .#{} --command bash -c ':'

  # build bundles
  temp="$(mktemp --directory)"
  trap "rm -rf $temp" SIGINT SIGTERM ERR EXIT
  nix bundle --out-link "$temp/shell" --bundler .# .#shell
  nix bundle --out-link "$temp/terminal" --bundler .# .#terminal

# Apply the first generation of a home-manager configuration.
[private]
init-home-manager host_name: install-git-hooks
    nix run .#homeManager -- switch --flake .#{{ host_name }}

# Apply the first generation of a nix-darwin configuration.
[private]
init-nix-darwin host_name: install-git-hooks
    nix run .#nixDarwin -- switch --flake .#{{ host_name }}

# Generate the Table of Contents in the README
[private]
codegen-readme:
    npm exec --package=markdown-toc -- markdown-toc --bullets '-' -i README.md

# Generate a file with a list of all my neovim plugins
[private]
codegen-neovim:
    #!/usr/bin/env bash
    set -euo pipefail

    readarray -t config_files < <(find ./dotfiles/neovim/lua -type f -name '*.lua')
    cat \
        <(sg --lang lua --pattern "Plug '"'$ARG'"'" --json=compact "${config_files[@]}" | jq --raw-output '.[].metaVariables.single.ARG.text') \
        <(sg --lang lua --pattern 'Plug "$ARG"' --json=compact "${config_files[@]}" | jq --raw-output '.[].metaVariables.single.ARG.text') \
    | sort --unique | cut -d'/' -f2 | head -c -1 > ./dotfiles/neovim/plugin-names.txt

# Pull changes from git remote
[private]
pull:
    #!/usr/bin/env fish
    # return if there is nothing to pull
    chronic git fetch
    if test -z "$(git log HEAD..@{u} --oneline)"
        echo 'Nothing to do.'
        return
    end

    # Show the new commits that would be pulled
    echo 'Commits made since last pull:'
    git log ..@{u}
    echo

    # if there are changes, warn the user in the prompt
    set status_output "$(git status --porcelain)"
    if test -n "$status_output"
        set warning "$(echo -s (set_color yellow) ' (WARNING: The working directory is not clean)' (set_color normal))"
    else
        set warning ''
    end
    read --prompt-str "Would you like to update$warning? (y/n): " --nchars 1 response
    if test $response = 'y'
        git pull
    end

# Commit changes to git remote
[private]
commit:
    #!/usr/bin/env fish
    # check if there are changes to commit
    set status_output "$(git status --porcelain)"
    if test -n "$status_output"
        git status
        read --prompt-str "Do you want to make a commit to your dotfiles? (y/n): " --nchars 1 response
        if test $response = 'y'
            git add --all
            git commit --message 'chore: upgrade tools'
        end
    else
        echo 'Nothing to commit.'
    end
