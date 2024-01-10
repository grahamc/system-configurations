set shell := ["bash", "-uc"]

# Display this message
help:
    @just --list --justfile {{ justfile() }} --unsorted

# Install git hooks
install-git-hooks:
    lefthook install

# Run precommit git hook
run-precommit-hook:
    lefthook run pre-commit

# Generate the Table of Contents in the README
generate-toc:
    npm exec --package=markdown-toc -- markdown-toc --bullets '*' -i README.md
