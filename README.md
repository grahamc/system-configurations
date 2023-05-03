# dotfiles

Configs and whatnot. Managed with [Home Manager for Nix](https://github.com/nix-community/home-manager). Works on Linux and macOS.

## Link

1. Clone the repository and go into its directory by running `git clone https://github.com/bigolu/dotfiles.git ~/.dotfiles && cd ~/.dotfiles`.

2. Apply the Home Manager configuration by running `nix --extra-experimental-features "nix-command flakes" run home-manager/master -- --extra-experimental-features "nix-command flakes" switch --flake .#<host_name> --update-input my-overlay --update-input smart-plug` where `<host_name>` is one of the hosts specified in the [flake.nix](https://github.com/bigolu/dotfiles/blob/master/flake.nix).

## Run

### With Nix

- Run the shell with `nix --extra-experimental-features 'nix-command flakes' run --update-input my-overlay github:bigolu/dotfiles`
- Run a specific command in the shell with `nix --extra-experimental-features 'nix-command flakes' run github:bigolu/dotfiles -- -c 'nvim some-file.py'`

### Standalone executable (Linux, with [fuse](https://github.com/libfuse/libfuse) installed, only)

- Run the shell with `sh -c "$(curl -fsSL https://raw.githubusercontent.com/bigolu/dotfiles/master/.meta/run-shell.sh)"`
- Run a specific program in the shell with `sh -c "$(curl -fsSL https://raw.githubusercontent.com/bigolu/dotfiles/master/.meta/run-shell.sh)" shell -c 'nvim some-file.py'`

  > **WARNING**: The standalone executable is not recommended for machines that already have Nix installed since the host Nix store, `/nix`, will be shadowed by the Nix store in the executable.
  >
  > NOTE: To run the executable in a docker container the container needs to be run in privileged mode. For example: `docker run --privileged --rm -it --entrypoint bash nixos/nix`

## Setting up Nix

### Installation

You can install Nix with the [Determinate Systems Installer](https://github.com/DeterminateSystems/nix-installer) (recommended) or the [official installer](https://nixos.org/download.html). The README for the Determinate Systems installer lists the differences between the two.

### Adding the Cache

To avoid building everything on your machine, you can enable this repository's Nix binary cache on your local machine using the steps below:

1. [Check to see if you are a trusted user](#check-trust). If you aren't, then [add yourself to the trusted users](#add-trust).

2. After running one of the `nix` commands from the [Link](#link) or [Run](#run) sections above, reply yes to the prompts to add the cache.

### Troubleshooting

- **Cache is being ignored**: First, [check to see if you are a trusted user](#check-trust). If you aren't, then [add yourself to the trusted users](#add-trust). Then enable the cache by adding the lines below to your config in `~/.config/nix/nix.conf` (If you have a multi-user Nix installation, you'll need to [restart the Nix daemon](#restart-daemon) afterwards to apply the changes.):

        extra-substituters = https://bigolu.cachix.org
        extra-trusted-substituters = https://bigolu.cachix.org
        extra-trusted-public-keys = bigolu.cachix.org-1:AJELdgYsv4CX7rJkuGu5HuVaOHcqlOgR07ZJfihVTIw=

### How To

- <span id="restart-daemon">Restart the Nix daemon</span>:

  - Linux: Run `systemctl restart nix-daemon.service`

  - macOS: Run `sudo launchctl stop org.nixos.nix-daemon && sudo launchctl start org.nixos.nix-daemon`

- <span id="check-trust">Check if you are a trusted user</span>:

  - single-user Nix installation: The user that installed Nix is always trusted in a single user installation.

  - multi-user Nix installation: Run `nix show-config` and look for your `$USER` in the `trusted-users` key.

- <span id="add-trust">Add yourself to the trusted users</space>:

  - Run `echo "extra-trusted-users = $USER" | sudo tee -a /etc/nix/nix.conf` to add yourself as a trusted user in the Nix system configuration. Then [restart the Nix daemon](#restart-daemon) to apply the changes.
