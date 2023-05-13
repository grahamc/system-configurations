# dotfiles

Configs and whatnot. Uses [Home Manager](https://github.com/nix-community/home-manager), [nix-darwin](https://github.com/LnL7/nix-darwin), and [flake-parts](https://flake.parts). Works on Linux and macOS.

## Link

First, clone the repository and go into its directory by running `git clone https://github.com/bigolu/dotfiles.git ~/.dotfiles && cd ~/.dotfiles`. The next steps depend on which host manager you're using.

### Home Manager

1. Apply the Home Manager configuration by running `nix run home-manager/master -- switch --flake .#<host_name>` where `<host_name>` is one of the hosts defined in the [Home Manager flake module](https://github.com/bigolu/dotfiles/blob/master/flake-modules/home-manager.nix).

### nix-darwin

1. I install some Homebrew packages through nix-darwin, but nix-darwin doesn't provide brew so you'll have to install it yourself. Check the site for instructions: [brew.sh](https://brew.sh/).

2. Unlike Home Manager, nix-darwin doesn't have a flake app output (though there is an [open issue](https://github.com/LnL7/nix-darwin/issues/398) to add it) so it will need to be set up using the non-flake installer:

    1. Run `nix build .#legacyPackages.darwinConfigurations.<host_name>.system` where `<host_name>` is one of the hosts defined in the [nix-darwin flake module](https://github.com/bigolu/dotfiles/blob/master/flake-modules/nix-darwin.nix). This will build the nix-darwin configuration in a folder named `result` in the current directory.
    2. Run `./result/sw/bin/darwin-rebuild switch --flake .<host_name>` where `<host_name>` is the same one you used in the last step. This will apply the configuration to your host. You can now remove the `result` folder with `rm -rf ./result`.

## Run

### With Nix

- Run the shell with `nix run github:bigolu/dotfiles`
- Run a specific command in the shell with `nix run github:bigolu/dotfiles -- -c 'nvim some-file.py'`

### Standalone executable (Linux, with [fuse](https://github.com/libfuse/libfuse) installed, only)

- Run the shell with `sh -c "$(curl -fsSL https://raw.githubusercontent.com/bigolu/dotfiles/master/.github/run-shell.sh)"`
- Run a specific program in the shell with `sh -c "$(curl -fsSL https://raw.githubusercontent.com/bigolu/dotfiles/master/.github/run-shell.sh)" shell -c 'nvim some-file.py'`

  > **WARNING**: The standalone executable is not recommended for machines that already have Nix installed since the host Nix store, `/nix`, will be shadowed by the Nix store in the executable.
  >
  > NOTE: To run the executable in a docker container the container needs to be run in privileged mode. For example: `docker run --privileged --rm -it --entrypoint bash nixos/nix`

## Setting up Nix

### Installation

I recommend installing Nix with the following command:

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- \
       install --extra-conf "trusted-users = $(whoami)"
```

This uses the [Determinate Systems Installer](https://github.com/DeterminateSystems/nix-installer) with one extra option set, `trusted-users`, so that your user is added to the list of trusted users during the installation. In Nix, some actions require that your user is trusted, such as adding a cache ([explained below](#adding-the-cache)). Having this set during installation allows you start using Nix immediately after installing without having to edit any configuration files.

Alternatively, you can use the [official installer](https://nixos.org/download.html), though this one has more steps. The README for the Determinate Systems installer lists the differences between the two.

### Adding the Cache

To avoid building everything on your machine, you can configure Nix to use this repository's package cache using the steps below:

1. [Check to see if you are a trusted user](#check-trust). If you aren't, then [add yourself to trusted-users](#add-trust).

2. After running one of the `nix` commands from the [Link](#link) or [Run](#run) sections above, reply yes to the prompts to add the cache.

## Troubleshooting

- **Cache is being ignored**: First, [check to see if you are a trusted user](#check-trust). If you aren't, then [add yourself to trusted-users](#add-trust). Then enable the cache by adding the lines below to your config in `~/.config/nix/nix.conf` (If you have a multi-user Nix installation, you'll need to [restart the Nix daemon](#restart-daemon) afterward to apply the changes.):

        extra-substituters = https://bigolu.cachix.org
        extra-trusted-substituters = https://bigolu.cachix.org
        extra-trusted-public-keys = bigolu.cachix.org-1:AJELdgYsv4CX7rJkuGu5HuVaOHcqlOgR07ZJfihVTIw=

- **apfs.util isn't working**: Make sure that the `/etc/synthetic.conf` has the permission `0644`.

## How To

- <span id="restart-daemon">Restart the Nix daemon</span>:

  - Linux: Run `systemctl restart nix-daemon.service`

  - macOS: Run `sudo launchctl stop org.nixos.nix-daemon && sudo launchctl start org.nixos.nix-daemon`

- <span id="check-trust">Check if you are a trusted user</span>:

  - single-user Nix installation: The user that installed Nix is always trusted in a single user installation.

  - multi-user Nix installation: Run `nix show-config` and look for your `$USER` in the `trusted-users` key.

- <span id="add-trust">Add yourself to trusted-users</space>:

  - Run `echo "extra-trusted-users = $USER" | sudo tee -a /etc/nix/nix.conf` to add yourself as a trusted user in the Nix system configuration. Then [restart the Nix daemon](#restart-daemon) to apply the changes.
