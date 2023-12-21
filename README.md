# System Config

The configuration for my development environment. Uses [Home Manager][home-manager] and [nix-darwin][nix-darwin]. Works on Linux and macOS.

## Applying the configuration

First, clone the repository and go into its directory by running `git clone https://github.com/bigolu/dotfiles.git ~/.dotfiles && cd ~/.dotfiles`. The next steps depend on which host manager you're using.

### Home Manager

1. Apply the Home Manager configuration by running `nix run home-manager/master -- switch --flake .#<host_name>` where `<host_name>` is one of the hosts defined in the [Home Manager flake module][home-manager-flake-module].

### nix-darwin

1. Disable System Integrity Protection for `yabai`. Instructions can be found on the [yabai wiki][yabai-wiki].

2. I install some Homebrew packages through nix-darwin, but nix-darwin doesn't provide brew so you'll have to install it yourself. Check the site for instructions: [brew.sh][brew].

3. Apply the nix-darwin configuration by running `nix run nix-darwin -- switch --flake .#<host_name>` where `<host_name>` is one of the hosts defined in the [nix-darwin flake module][nix-darwin-flake-module].

4. Some settings applied by nix-darwin only take effect after a restart so do a restart now.

5. Additional Setup

    * Keyboard:

        * Set the keyboard input source to 'Others → (No Accent Keys)'.

        * Disable the built-in keyboard shortcut for switching input sources, `ctrl+space`.

        * Disable the built-in keyboard shortcuts for switching workspaces, `ctrl+left` and `ctrl+right`.

    * Setup Hammerspoon using the instructions in the [Hammerspoon Getting Started Guide][hammerspoon-guide].

    * Open Finicky to set it as the default browser.

    * Open MonitorControl, UnnaturalScrollWheels, Nightfall, and "Mac Mouse Fix" to configure them.

## Running the home configuration

### Using Nix

* Run the shell with `nix run github:bigolu/dotfiles`

### Using a Standalone Executable

My home config is also available as an executable with no dependencies. The executable is a self-extracting archive (SEA) that contains all the command-line programs I use, as well as my config files for them. Running it will start my shell which will have access to these programs and configs.

* Run the shell with `sh -c "$(curl -fsSL https://raw.githubusercontent.com/bigolu/dotfiles/master/.github/run-shell.sh)"`

  > NOTE: While the SEA doesn't depend on any programs on your computer, it does require that you have a `/tmp` directory. You can read this [GitHub issue comment][rootless-nix] regarding a "rootless Nix" to see why this is needed, as well as learn more about how this works.

## Setting up Nix

### Installation

#### Determinate Systems Installer (recommended)

I recommend using the [Determinate Systems Installer][ds-installer] with an extra option set:

* `trusted-users`: This adds the current user to the list of trusted users. In Nix, some actions require that your user is trusted, such as adding a cache ([explained below](#adding-the-cache)). Setting this allows you start using Nix immediately after installation without having to edit any configuration files.

Here is what the installation command will look like with the addition of the extra option:

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- \
       install \
         --extra-conf "trusted-users = $(whoami)"
```

> NOTE: Please confirm that everything in the command provided above, besides the extra option, is up-to-date with what is currently listed on the [Installer Website][ds-installer].

#### Official Installer

Alternatively, you can use the [official installer][official-installer], though this one has more steps. The README for the [Determinate Systems installer][ds-installer] lists the differences between the two.

### Adding the Cache

To avoid building everything on your machine, you can configure Nix to use this repository's package cache using the steps below:

1. [Check to see if you are a trusted user](#check-trust). If you aren't, then [add yourself to trusted-users](#add-trust).

2. After running one of the `nix` commands from the [Apply](#applying-the-configuration) or [Run](#running-the-home-configuration) sections above, reply yes to the prompts to add the cache.

## Troubleshooting

* **Cache is being ignored**: First, [check to see if you are a trusted user](#check-trust). If you aren't, then [add yourself to trusted-users](#add-trust). Since I do not know of a way to have nix re-prompt you to add the cache you will have to do it manually. You can do this by adding the lines below to your config in `~/.config/nix/nix.conf` (If you have a multi-user Nix installation, you'll need to [restart the Nix daemon](#restart-daemon) afterward to apply the changes.):

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

* <span id="add-trust">Add yourself to trusted-users</span>:

  * Run `echo "extra-trusted-users = $USER" | sudo tee -a /etc/nix/nix.conf` to add yourself as a trusted user in the Nix system configuration. Then [restart the Nix daemon](#restart-daemon) to apply the changes.

[ds-installer]:https://github.com/DeterminateSystems/nix-installer
[official-installer]:https://nixos.org/download.html
[home-manager]:https://github.com/nix-community/home-manager
[nix-darwin]:https://github.com/LnL7/nix-darwin
[home-manager-flake-module]:https://github.com/bigolu/dotfiles/blob/master/flake-modules/home-manager/default.nix
[yabai-wiki]:https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection
[brew]:https://brew.sh/
[nix-darwin-flake-module]:https://github.com/bigolu/dotfiles/blob/master/flake-modules/nix-darwin/default.nix
[hammerspoon-guide]:https://www.hammerspoon.org/go/
[rootless-nix]:https://github.com/NixOS/nix/issues/1971#issue-304578884
