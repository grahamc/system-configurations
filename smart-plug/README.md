# Smart Plug Controller

Turns on a smart plug after the computer starts up or is woken up. Turns the plug off before the computer suspends, hibernates, restarts, or shuts down.

## Why

If you leave studio monitors on while turning off the sound source, you will get a loud POP noise, which [isn't good for the speakers](https://www.sweetwater.com/insync/power-power-off-sequence/). With this script, I can make sure that my monitors are always turned off before my computer, the source, turns off.

## Requirements

- [nix](https://nixos.org/) -- for dependencies
- A linux distribution that uses [systemd](https://systemd.io/) -- for scheduling when the controller should run
- A Kasa smart plug with the alias 'plug'

## Run

- Run `nix run` in this directory.

## Installation (Requires [Home Manager for Nix](https://github.com/nix-community/home-manager))

The Nix flake in this directory has an output with a Home Manager module for running this as a systemd user service. The output is `legacyPackages.<system>.homeManagerModules.smart-plug`. You can run `nix flake show` to find the supported systems.

## Development

- In your terminal, run `nix develop` in this directory and all the dependencies will be loaded into that shell. To get autocomplete in your IDE, launch it from this shell. This way it will refer to the correct `python` executable, the one provided by nix. Alternatively, there may be an extension for your IDE that can load a nix shell. This way you don't have to launch it from the terminal.

> **TIP**: If you have [direnv](https://direnv.net) installed, it will automatically load the nix dependencies when you enter this directory and unload it when you leave the directory :)

## Resources

- [login1 dbus interface](https://www.freedesktop.org/software/systemd/man/org.freedesktop.login1.html)
- [inhibitor API](https://www.freedesktop.org/wiki/Software/systemd/inhibit/)
- [stackoverflow post](https://stackoverflow.com/questions/33428804/role-of-mainloops-event-loops-in-dbus-service) on how dbus-python integrates with a mainloop
- [intro to dbus](https://www.freedesktop.org/wiki/IntroductionToDBus/)
- This [stackoverflow post](https://unix.stackexchange.com/questions/337853/how-can-i-trigger-a-systemd-unit-on-suspend-before-networking-is-shut-down) where the poster explains why a pure systemd service solution doesn't work and provides a repo with a working solution. I started with their code and adapted it to my specific use case
- [Stackoverflow post](https://unix.stackexchange.com/questions/152039/how-to-run-a-user-script-after-systemd-wakeup) on why a user service would not work
