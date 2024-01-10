set shell := ["bash", "-uc"]

default:
  @just --choose

# Display this message
help:
    @just --list --justfile {{ justfile() }} --unsorted

# Install git hooks
install-git-hooks:
    lefthook install

# Run precommit git hook
run-precommit-hook:
    lefthook run pre-commit

init-home-manager host_name: install-git-hooks
    nix run .#homeManager -- switch --flake .#{{host_name}}

init-nix-darwin host_name: install-git-hooks
    nix run .#nixDarwin -- switch --flake .#{{host_name}}

# Generate the Table of Contents in the README
generate-toc:
    npm exec --package=markdown-toc -- markdown-toc --bullets '*' -i README.md
