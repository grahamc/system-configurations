# dotfiles

Configs and whatnot. Uses [Home Manager](https://github.com/nix-community/home-manager), [nix-darwin](https://github.com/LnL7/nix-darwin), and [flake-parts](https://flake.parts). Works on Linux and macOS.

## Applying the configuration

First, clone the repository and go into its directory by running `git clone https://github.com/bigolu/dotfiles.git ~/.dotfiles && cd ~/.dotfiles`. The next steps depend on which host manager you're using.

### Home Manager

1. Apply the Home Manager configuration by running `nix run home-manager/master -- switch --flake .#<host_name>` where `<host_name>` is one of the hosts defined in the [Home Manager flake module](https://github.com/bigolu/dotfiles/blob/master/flake-modules/home-manager/default.nix).

### nix-darwin

1. Disable System Integrity Protection for `yabai`. Instructions can be found on the [yabai wiki](https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection).

2. I install some Homebrew packages through nix-darwin, but nix-darwin doesn't provide brew so you'll have to install it yourself. Check the site for instructions: [brew.sh](https://brew.sh/).

3. Unlike Home Manager, nix-darwin doesn't have a flake app output (though there is an [open issue](https://github.com/LnL7/nix-darwin/issues/398) to add it) so it will need to be set up using the non-flake installer:

    1. Run `nix build .#darwinConfigurations.<host_name>.system` where `<host_name>` is one of the hosts defined in the [nix-darwin flake module](https://github.com/bigolu/dotfiles/blob/master/flake-modules/nix-darwin/default.nix). This will build the nix-darwin configuration in a folder named `result` in the current directory.
    2. Run `./result/sw/bin/darwin-rebuild switch --flake .#<host_name>` where `<host_name>` is the same one you used in the last step. This will apply the configuration to your host. You can now remove the `result` folder with `rm -rf ./result`.

4. Some of the settings applied by nix-darwin only take effect after a restart so do a restart now.

5. Additional Setup

    * Keyboard:

        * Set the keyboard input source to 'Others -> (No Accent Keys)'.

        * Disable the builtin keyboard shortcut for switching input sources, `ctrl+space`.

        * Disable the builtin keyboard shortcuts for switching workspaces, `ctrl+left` and `ctrl+right`.

        * Open 9 desktops then open keyboard shortcuts and enable the shortcuts for jumping to a desktop, `ctrl+[1-9]`

    * Setup Hammerspoon using the instructions in the [Hammerspoon Getting Started Guide](https://www.hammerspoon.org/go/).

    * Open SpaceID, right click its icon, and select 'Launch on Login' to set it as a login app.

    * Open Finicky to set it as the default browser.

## Running the home configuration

### Using Nix

* Run the shell with `nix run github:bigolu/dotfiles`

### Using a Standalone Executable

My home config is also available as an executable with no dependencies. The executable is a self-extracting archive (SEA) that contains all the commandline programs I use, as well as my config files for them. Running it will start my shell which will have access to these programs and configs.

* Run the shell with `sh -c "$(curl -fsSL https://raw.githubusercontent.com/bigolu/dotfiles/master/.github/run-shell.sh)"`

  > NOTE: While the SEA doesn't depend on any programs on your computer, it does require that you have a `/tmp` directory. You can read this [GitHub issue comment](https://github.com/NixOS/nix/issues/1971#issue-304578884) regarding a "rootless Nix" to see why this is needed, as well as learn more about how this works.

## Setting up Nix

### Installation

I recommend installing Nix with the following command:

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- \
       install \
         --extra-conf "trusted-users = $(whoami)"
```

This uses the [Determinate Systems Installer](https://github.com/DeterminateSystems/nix-installer) with an extra option set:

* `trusted-users`: This adds the current user to the list of trusted users. In Nix, some actions require that your user is trusted, such as adding a cache ([explained below](#adding-the-cache)). Setting this allows you start using Nix immediately after installation without having to edit any configuration files.

Alternatively, you can use the [official installer](https://nixos.org/download.html), though this one has more steps. The README for the Determinate Systems installer lists the differences between the two.

### Adding the Cache

To avoid building everything on your machine, you can configure Nix to use this repository's package cache using the steps below:

1. [Check to see if you are a trusted user](#check-trust). If you aren't, then [add yourself to trusted-users](#add-trust).

2. After running one of the `nix` commands from the [Apply](#applying-the-configuration) or [Run](#running-the-home-configuration) sections above, reply yes to the prompts to add the cache.

## Troubleshooting

* **Cache is being ignored**: First, [check to see if you are a trusted user](#check-trust). If you aren't, then [add yourself to trusted-users](#add-trust). Then enable the cache by adding the lines below to your config in `~/.config/nix/nix.conf` (If you have a multi-user Nix installation, you'll need to [restart the Nix daemon](#restart-daemon) afterward to apply the changes.):

    ``` conf
        extra-substituters = https://bigolu.cachix.org
        extra-trusted-substituters = https://bigolu.cachix.org
        extra-trusted-public-keys = bigolu.cachix.org-1:AJELdgYsv4CX7rJkuGu5HuVaOHcqlOgR07ZJfihVTIw=
    ```

* **apfs.util isn't working**: Make sure that the `/etc/synthetic.conf` has the permission `0644`.

## How To

* <span id="restart-daemon">Restart the Nix daemon</span>:

  * Linux: Run `systemctl restart nix-daemon.service`

  * macOS: Run `sudo launchctl stop org.nixos.nix-daemon && sudo launchctl start org.nixos.nix-daemon`

* <span id="check-trust">Check if you are a trusted user</span>:

  * single-user Nix installation: The user that installed Nix is always trusted in a single user installation.

  * multi-user Nix installation: Run `nix show-config` and look for your `$USER` in the `trusted-users` key.

* <span id="add-trust">Add yourself to trusted-users</space>:

  * Run `echo "extra-trusted-users = $USER" | sudo tee -a /etc/nix/nix.conf` to add yourself as a trusted user in the Nix system configuration. Then [restart the Nix daemon](#restart-daemon) to apply the changes.
