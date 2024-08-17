# System Configurations

[![built with nix][built-with-nix-badge]][built-with-nix-site]

This repository holds the [Home Manager][home-manager] and [nix-darwin][nix-darwin] configurations for my machines.
I don't expect anyone else to use this,
but I figured I'd leave the repo public as a resource for people who want to manage
their systems similarly.

## Table of Contents

<!--
  DO NOT EDIT THE TABLE OF CONTENTS MANUALLY.
  It gets generated by markdown-toc:
  https://github.com/jonschlinkert/markdown-toc
  To regenerate, run `just codegen-readme`. Though the pre-commit hook will
  automatically run this for you.
-->

<!-- toc -->

- [Prerequisites](#prerequisites)
  - [Installing Nix](#installing-nix)
  - [Using the Binary Cache (optional)](#using-the-binary-cache-optional)
- [Applying a Configuration](#applying-a-configuration)
  - [Linux](#linux)
  - [macOS](#macos)
- [Running the Home Configuration](#running-the-home-configuration)
- [Troubleshooting](#troubleshooting)
- [How-tos](#how-tos)

<!-- tocstop -->

## Prerequisites

To [apply a configuration](#applying-a-configuration), you'll need
[Nix][nix], a package manager. This section will show you how to install Nix and configure it to use this
repository's binary cache to speed up builds.

### Installing Nix

I recommend using the [Determinate Systems installer][determinate-systems-installer] over the
[official installer][official-installer] for the following reasons:

- It has an uninstaller
- It enables two experimental features that are used in this readme, flakes and a new commandline interface.

You can find more differences between the two in the
["Installation Differences" section of the Determinate Systems Installer README][determinate-systems-installer-differences].

When using the installer I suggest adding an extra option, `trusted-users`, which will add the current user to the list
of trusted users. This is helpful since some actions in Nix require that the user be trusted, such as using a
binary cache ([explained below](#using-the-binary-cache-optional)). Below is the installation command with the
extra option:

> NOTE: Please confirm that everything in the command provided above, besides the extra option, is up-to-date with
> what is currently listed on the [Installer Website][determinate-systems-installer].

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
  | sh -s -- install --extra-conf "trusted-users = $(whoami)"
```

<!-- Adding this since the link generated by markdown-toc doesn't match what GitHub generated -->

<span id="using-the-binary-cache-optional"></span>

### Using the Binary Cache (optional)

To avoid having to build everything on your machine, you can configure Nix to use this repository's binary cache using
the steps below:

1. [Check to see if you are a trusted user](#check-trust). If you aren't, then
   [add yourself to trusted-users](#add-trust).

2. After running one of the `nix` commands from the
   ["Applying a Configuration" section](#applying-a-configuration) or
   ["Running the Home Configuration" section](#running-the-home-configuration) below, reply yes to the prompts to add
   the cache.

## Applying a Configuration

1. Start a shell with the required programs by first running `nix shell --impure nixpkgs#fish nixpkgs#direnv nixpkgs#git --command fish` and then running `direnv hook fish | source`.

2. Clone the repository and go into its directory by running
   `git clone https://github.com/bigolu/system-configurations.git ~/code/system-configurations && cd ~/code/system-configurations`

3. Run `direnv allow` to set up the development environment.

The next steps depend on the operating system you're using:

### Linux

1. Apply the Home Manager configuration by running `just init-home-manager <host_name>`
   where `<host_name>` is one of the hosts defined in the [Home Manager flake module](flake-modules/home-manager/default.nix).

2. Additional Setup

   - Install and start [`keyd`][keyd]

   - Run the following commands from the root of the repository. These commands run scripts that require root privileges and therefore can't be done in Home Manager:

     - `./dotfiles/nix/set-locale-variable.bash`

     - `./dotfiles/nix/nix-fix/install-nix-fix.bash`

     - `./dotfiles/nix/systemd-garbage-collection/install.bash`

     - `./dotfiles/smart_plug/linux/install.bash`

     - `./dotfiles/linux/set-keyboard-to-mac-mode.sh`

     - `./dotfiles/keyd/install.bash`

     - `./dotfiles/firefox-developer-edition/set-default-browser.sh`

   - Apply the Firefox `about:config` changes in `dotfiles/firefox-developer-edition/about-config-changes.txt`

### macOS

1. Partially disable System Integrity Protection for `yabai`. Instructions can be found on the [yabai wiki][yabai-wiki].

2. I install some Homebrew packages through nix-darwin, but nix-darwin doesn't provide brew so you'll have to install
   it yourself. Check the site for instructions: [brew.sh][brew].

3. Apply the nix-darwin configuration by running `just init-nix-darwin <host_name>` where
   `<host_name>` is one of the hosts defined in the [nix-darwin flake module](flake-modules/nix-darwin/default.nix).

4. [Some settings in nix-darwin only take effect after a logout/restart](https://github.com/LnL7/nix-darwin/issues/658) so restart now.

5. Additional Setup

   - Keyboard:

     - Set the keyboard input source to 'Others → (No Accent Keys)'.

     <!--
       I can automate shortcuts when this issue gets resolved:
       https://github.com/LnL7/nix-darwin/issues/185
     -->

     - Shortcuts:

       - Disable: "Select the previous input source" `ctrl+space`, "Application windows" `ctrl+↓`

       - Change: "Mission Control → Move left/right a space" to `cmd+[` and `cmd+]` respectively, "Mission Control" to `cmd+d`, "Mission Control → Switch to Desktop 1-9" `cmd+[1-9]`

   - Open Hammerspoon, Finicky, MonitorControl, UnnaturalScrollWheels, Nightfall, and "Mac Mouse Fix" to configure them.

## Running the Home Configuration

You can also run a shell or terminal with the home configuration already loaded in it. This is helpful when you only
need to use the configuration temporarily and not apply it, like when you're in a remote host. The executable is a self-extracting archive
(SEA) that contains all the command-line programs I use, as well as my config files for them.
Just run one of these commands, depending on whether you have `wget` or `curl`:

`curl -fsSL https://raw.githubusercontent.com/bigolu/system-configurations/master/.github/run.sh | sh -s -- <type>`

`wget -qO- https://raw.githubusercontent.com/bigolu/system-configurations/master/.github/run.sh | sh -s -- <type>`

where `<type>` can be `shell` or `terminal`.

> NOTE: While the SEA doesn't depend on any programs on your computer, it does require that you have a `/tmp`
> directory. You can read this [GitHub issue comment regarding a "rootless Nix"][rootless-nix] to see why this is
> needed, as well as learn more about how this works.

## Troubleshooting

- **Cache is being ignored**: First, [check to see if you are a trusted user](#check-trust). If you aren't, then
  [add yourself to trusted-users](#add-trust). Since I don't know of a way to have Nix re-prompt you to add the cache
  you'll have to do it manually. You can do this by adding the lines below to your config in `~/.config/nix/nix.conf`
  (If you have a multi-user Nix installation, you'll need to [restart the Nix daemon](#restart-daemon) afterward to apply the changes.):

  ```properties
  extra-substituters = https://bigolu.cachix.org
  extra-trusted-substituters = https://bigolu.cachix.org
  extra-trusted-public-keys = bigolu.cachix.org-1:AJELdgYsv4CX7rJkuGu5HuVaOHcqlOgR07ZJfihVTIw=
  ```

- **`apfs.util` isn't working**: Make sure that `/etc/synthetic.conf` has the permission `0644`.

## How-tos

- <span id="restart-daemon">Restart the Nix daemon</span>:

  - Linux: Run `systemctl restart nix-daemon.service`

  - macOS: Run `sudo launchctl stop org.nixos.nix-daemon && sudo launchctl start org.nixos.nix-daemon`

- <span id="check-trust">Check if you are a trusted user</span>:

  - single-user Nix installation: The user that installed Nix is always trusted in a single user installation.

  - multi-user Nix installation: Run `nix show-config` and look for your `$USER` in the `trusted-users` key.

- <span id="add-trust">Add yourself to trusted-users</span>:

  - Run `echo "extra-trusted-users = $USER" | sudo tee -a /etc/nix/nix.conf` to add yourself as a trusted user in the
    Nix system configuration. Then [restart the Nix daemon](#restart-daemon) to apply the changes.

[determinate-systems-installer]: https://github.com/DeterminateSystems/nix-installer
[determinate-systems-installer-differences]: https://github.com/DeterminateSystems/nix-installer#installation-differences
[official-installer]: https://nixos.org/download.html
[home-manager]: https://github.com/nix-community/home-manager
[nix-darwin]: https://github.com/LnL7/nix-darwin
[yabai-wiki]: https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection
[brew]: https://brew.sh/
[rootless-nix]: https://github.com/NixOS/nix/issues/1971#issue-304578884
[built-with-nix-site]: https://builtwithnix.org
[built-with-nix-badge]: https://builtwithnix.org/badge.svg
[nix]: https://nixos.org/learn
[keyd]: https://github.com/rvaiya/keyd
