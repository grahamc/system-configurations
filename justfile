set shell := ["bash", "-uc"]

# Choose a task. Only includes tasks that don't take arguments.
default:
    @just --choose

# Display a list of all tasks.
help:
    @just --list --justfile {{ justfile() }} --unsorted

# Reload direnv
reload:
    nix-direnv-reload

# Apply the first generation of a home-manager configuration.
init-home-manager host_name: install-git-hooks
    nix run .#homeManager -- switch --flake .#{{ host_name }}

# Apply the first generation of a nix-darwin configuration.
init-nix-darwin host_name: install-git-hooks
    nix run .#nixDarwin -- switch --flake .#{{ host_name }}

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
[private]
format:
    treefmt

# Install git hooks
[private]
install-git-hooks:
    lefthook install

# Run precommit git hook
[private]
run-precommit-hook:
    lefthook run pre-commit

# Generate the Table of Contents in the README
[private]
generate-toc:
    npm exec --package=markdown-toc -- markdown-toc --bullets '-' -i README.md

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
