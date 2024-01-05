# System Config

[![built with nix][built-with-nix-badge]][built-with-nix-site]

The configuration for my development environment on Linux and macOS. Uses
[Home Manager][home-manager] and [nix-darwin][nix-darwin]. I don't expect anyone else to use this,
but I figured I'd leave the repository public as a resource for people who want to manage
their systems similarly.

Table of Contents

<!--
  DO NOT EDIT THE TABLE OF CONTENTS MANUALLY.
  It gets generated by markdown-toc: https://github.com/jonschlinkert/markdown-toc
  To regenerate, use this command: npm exec --package=markdown-toc -- markdown-toc --bullets '*' -i README.md
-->

<!-- toc -->

* [Setting up Nix](#setting-up-nix)
  * [Installation](#installation)
  * [Using the Binary Cache (optional)](#using-the-binary-cache-optional)
* [Applying the Configuration](#applying-the-configuration)
  * [Linux](#linux)
  * [macOS](#macos)
* [Running the Home Configuration](#running-the-home-configuration)
  * [Using Nix](#using-nix)
  * [Using a Standalone Executable](#using-a-standalone-executable)
* [Troubleshooting](#troubleshooting)
* [How To](#how-to)

<!-- tocstop -->

## Setting up Nix

To use any configuration, except for when you are
[running the home config from a standalone executable](#using-a-standalone-executable), you will need
[Nix][nix], a package manager. This section will show you how to install Nix and configure it to use this
repository's binary cache to speed up builds.

### Installation

I recommend using the [Determinate Systems installer][determinate-systems-installer] over the
[official installer][official-installer] for a few reasons:

* It has an uninstaller
* It's easier to use, as it only requires running a single command
* Sensible default settings

You can find more differences between the two in the
["Installation Differences" section of the Determinate Systems Installer README][determinate-systems-installer-differences].

When using the installer I suggest adding an extra option, `trusted-users`, which will add the current user to the list
of trusted users. This is helpful since some actions in Nix require that the user be trusted, such as using a
binary cache ([explained below](#using-the-binary-cache-optional)). Below is the installation command with the
extra option:

<pre>
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
  | sh -s -- install --extra-conf "trusted-users = $(whoami)"
</pre>

> NOTE: Please confirm that everything in the command provided above, besides the extra option, is up-to-date with
what is currently listed on the [Installer Website][determinate-systems-installer].

<!-- Adding this since the link generated by markdown-toc doesn't match what GitHub generated -->
<span id="using-the-binary-cache-optional"></span>

### Using the Binary Cache (optional)

To avoid having to build everything on your machine, you can configure Nix to use this repository's binary cache using
the steps below:

1. [Check to see if you are a trusted user](#check-trust). If you aren't, then
[add yourself to trusted-users](#add-trust).

2. After running one of the `nix` commands from the
["Applying the Configuration" section](#applying-the-configuration) or
["Running the Home Configuration" section](#running-the-home-configuration) below, reply yes to the prompts to add
the cache.

## Applying the Configuration

> Tip: To apply the configuration you can use a shell, or entire terminal, with the home configuration already loaded.
This is helpful for debugging any problems you encounter while applying the config since you'll have access to all the tools/shortcuts included in the home
config. Check the ["Running the Home Configuration" section](#running-the-home-configuration) for instructions.

1. Clone the repository and go into its directory by running
`git clone https://github.com/bigolu/dotfiles.git ~/.dotfiles && cd ~/.dotfiles`

The next steps depend on the operating system you're using:

### Linux

1. Apply the Home Manager configuration by running `nix run home-manager/master -- switch --flake .#<host_name>`
where `<host_name>` is one of the hosts defined in the [Home Manager flake module][home-manager-flake-module].

### macOS

1. Disable System Integrity Protection for `yabai`. Instructions can be found on the [yabai wiki][yabai-wiki].

2. I install some Homebrew packages through nix-darwin, but nix-darwin doesn't provide brew so you'll have to install
it yourself. Check the site for instructions: [brew.sh][brew].

3. Apply the nix-darwin configuration by running `nix run nix-darwin -- switch --flake .#<host_name>` where
`<host_name>` is one of the hosts defined in the [nix-darwin flake module][nix-darwin-flake-module].

4. Some settings applied by nix-darwin only take effect after a restart so do a restart now.

5. Additional Setup

    * Keyboard:

        * Set the keyboard input source to 'Others → (No Accent Keys)'.

        * Disable the built-in keyboard shortcut for switching input sources, `ctrl+space`.

        * Disable the built-in keyboard shortcuts for switching workspaces, `ctrl+left` and `ctrl+right`.

    * Setup Hammerspoon using the instructions in the [Hammerspoon Getting Started Guide][hammerspoon-guide].

    * Open Finicky to set it as the default browser.

    * Open MonitorControl, UnnaturalScrollWheels, Nightfall, and "Mac Mouse Fix" to configure them.

## Running the Home Configuration

You can also run a shell or terminal with the home configuration already loaded in it. This is helpful when you only
need to use the configuration temporarily and not apply it, like when using SSH.

### Using Nix

* Run the shell with `nix run --no-write-lock-file github:bigolu/dotfiles`
* Run the terminal with `nix run --no-write-lock-file github:bigolu/dotfiles#terminal`

### Using a Standalone Executable

My home config is also available as an executable with no dependencies. The executable is a self-extracting archive
(SEA) that contains all the command-line programs I use, as well as my config files for them. Running it will start a
shell/terminal that will have access to these programs and configs.

* Run the shell with
`curl -fsSL https://raw.githubusercontent.com/bigolu/dotfiles/master/.github/run.sh | sh -s -- shell`
* Run the terminal with
`curl -fsSL https://raw.githubusercontent.com/bigolu/dotfiles/master/.github/run.sh | sh -s -- terminal`

> NOTE: While the SEA doesn't depend on any programs on your computer, it does require that you have a `/tmp`
directory. You can read this [GitHub issue comment regarding a "rootless Nix"][rootless-nix] to see why this is
needed, as well as learn more about how this works.

## Troubleshooting

* **Cache is being ignored**: First, [check to see if you are a trusted user](#check-trust). If you aren't, then
[add yourself to trusted-users](#add-trust). Since I do not know of a way to have nix re-prompt you to add the cache
you will have to do it manually. You can do this by adding the lines below to your config in `~/.config/nix/nix.conf`
(If you have a multi-user Nix installation, you'll need to [restart the Nix daemon](#restart-daemon) afterward to apply the changes.):

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

  * Run `echo "extra-trusted-users = $USER" | sudo tee -a /etc/nix/nix.conf` to add yourself as a trusted user in the
  Nix system configuration. Then [restart the Nix daemon](#restart-daemon) to apply the changes.

[determinate-systems-installer]:https://github.com/DeterminateSystems/nix-installer
[determinate-systems-installer-differences]:https://github.com/DeterminateSystems/nix-installer#installation-differences
[official-installer]:https://nixos.org/download.html
[home-manager]:https://github.com/nix-community/home-manager
[nix-darwin]:https://github.com/LnL7/nix-darwin
[home-manager-flake-module]:https://github.com/bigolu/dotfiles/blob/master/flake-modules/home-manager/default.nix
[yabai-wiki]:https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection
[brew]:https://brew.sh/
[nix-darwin-flake-module]:https://github.com/bigolu/dotfiles/blob/master/flake-modules/nix-darwin/default.nix
[hammerspoon-guide]:https://www.hammerspoon.org/go/
[rootless-nix]:https://github.com/NixOS/nix/issues/1971#issue-304578884
[built-with-nix-site]:https://builtwithnix.org
[built-with-nix-badge]:https://builtwithnix.org/badge.svg
[nix]:https://nixos.org/learn
