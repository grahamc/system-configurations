# dotfiles

Configs and whatnot. Managed with [Home Manager for Nix](https://github.com/nix-community/home-manager). Works on Linux and macOS.

## Link

1. Clone the repo and go into the directory `git clone https://github.com/bigolu/dotfiles.git ~/.dotfiles && cd ~/.dotfiles`

2. Apply the Home Manager configuration `nix --extra-experimental-features "nix-command flakes" run home-manager/master -- --extra-experimental-features "nix-command flakes" switch --flake .#<host_name> --update-input my-overlay` where `<host_name>` is one of the hosts specified in the [flake.nix](https://github.com/bigolu/dotfiles/blob/master/flake.nix).

## Run

### With Nix

- To run the shell `nix --extra-experimental-features 'nix-command flakes' run github:bigolu/dotfiles`
- To run a specific command in the shell `nix --extra-experimental-features 'nix-command flakes' run github:bigolu/dotfiles -- -c 'nvim some-file.py'`

### Standalone executable (Linux only)

- To run the shell `sh -c "$(curl -fsSL https://raw.githubusercontent.com/bigolu/dotfiles/master/.meta/run-shell.sh)"`
- To run a specific program in the shell `sh -c "$(curl -fsSL https://raw.githubusercontent.com/bigolu/dotfiles/master/.meta/run-shell.sh)" shell -c 'nvim some-file.py'`

- > WARNING: The standalone executable is not recommended for machines that already have Nix installed since the host Nix store, `/nix`, will be shadowed by the Nix store in the executable.

- > NOTE: To run the executable in a docker container the container needs to be run in privileged mode. For example: `docker run --privileged --rm -it --entrypoint bash nixos/nix`