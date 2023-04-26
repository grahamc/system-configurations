# dotfiles

Configs and whatnot. Managed with [Home Manager for Nix](https://github.com/nix-community/home-manager). Works on Linux and macOS.

## Link

1. Clone the repository and go into the directory `git clone https://github.com/bigolu/dotfiles.git ~/.dotfiles && cd ~/.dotfiles`

2. Apply the Home Manager configuration `nix --extra-experimental-features "nix-command flakes" run home-manager/master -- --extra-experimental-features "nix-command flakes" switch --flake .#<host_name> --update-input my-overlay` where `<host_name>` is one of the hosts specified in the [flake.nix](https://github.com/bigolu/dotfiles/blob/master/flake.nix).

## Run

### With Nix

- To run the shell `nix --extra-experimental-features 'nix-command flakes' run --update-input my-overlay github:bigolu/dotfiles`
- To run a specific command in the shell `nix --extra-experimental-features 'nix-command flakes' run github:bigolu/dotfiles -- -c 'nvim some-file.py'`

### Standalone executable (Linux only)

- To run the shell `sh -c "$(curl -fsSL https://raw.githubusercontent.com/bigolu/dotfiles/master/.meta/run-shell.sh)"`
- To run a specific program in the shell `sh -c "$(curl -fsSL https://raw.githubusercontent.com/bigolu/dotfiles/master/.meta/run-shell.sh)" shell -c 'nvim some-file.py'`

  > WARNING: The standalone executable is not recommended for machines that already have Nix installed since the host Nix store, `/nix`, will be shadowed by the Nix store in the executable.

  > NOTE: To run the executable in a docker container the container needs to be run in privileged mode. For example: `docker run --privileged --rm -it --entrypoint bash nixos/nix`

## Setting up Nix

### Installation

You can install Nix with the [Determinate Systems Installer](https://github.com/DeterminateSystems/nix-installer) (recommended) or the [official installer](https://nixos.org/download.html). The README for the Determinate Systems installer lists the differences between the two.

### Adding the Cache

To avoid building everything on your machine, you can add my Nix binary cache using the steps below:

1. Make sure you are a trusted user. If you have a single-user Nix installation you don't have to do anything. If you have a multi-user installation then you need to add yourself as a trusted user:

   1. First check to see if you are already trusted by running `nix show-config` and looking for your `$USER` in the `trusted-users` key. If you're not there then run `echo "extra-trusted-users = $USER" | sudo tee -a /etc/nix/nix.conf` to set yourself as a trusted user in the Nix system configuration.
   2. Restart the nix daemon so your changes to the system configuration are applied:
      - **Linux**: Run `systemctl restart nix-daemon.service`
      - **macOS**: Run `sudo launchctl stop org.nixos.nix-daemon && sudo launchctl start org.nixos.nix-daemon`

2. After running one of the `nix` commands from the Link or Run sections above, just reply yes to the prompts to add the cache.

### Troubleshooting

- **Cache is being ignored**: Make sure you are a trusted user using the steps from 'Adding the Cache'. Then manually add the cache to your config in `~/.config/nix/nix.conf`:

        extra-substituters = https://bigolu.cachix.org
        extra-trusted-substituters = https://bigolu.cachix.org
        extra-trusted-public-keys = bigolu.cachix.org-1:AJELdgYsv4CX7rJkuGu5HuVaOHcqlOgR07ZJfihVTIw=
