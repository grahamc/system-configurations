# Smart Plug Controller

Turns on a smart plug after the computer starts up or is woken up. Turns the plug off before the computer suspends, hibernates, restarts, or shuts down.

## Why

If you leave studio monitors on while turning off the sound source, you will get a loud POP noise, which [isn't good for the speakers](https://www.sweetwater.com/insync/power-power-off-sequence/). With this script, I can make sure that my monitors are always turned off before my computer, the source source, turns off.

## Requirements

- [nix](https://nixos.org/) -- for dependencies
- A linux distribution that uses [systemd](https://systemd.io/) -- for scheduling when the controller should run
- A Kasa smart plug with the alias 'plug'

## Installation

> **NOTE**: Right now the systemd service (`smart-plug-daemon.service`) is hardcoded to look for `nix` in my home directory, so you'll have to change that before installing.

In your terminal, go to the directory containing this README and run `./install`.

## Development

- In your terminal, run `nix-shell` from the directory `smart-plug-daemon.d` and all the dependencies will be loaded into that shell. To get autocomplete in your IDE, launch it from this shell. This way it will refer to the correct `python` executable, the one provided by nix.

> **TIP**: If you have [direnv](https://direnv.net) installed, it will automatically load the nix dependencies when you enter the `smart-plug-daemon.d` directory and unload it when you leave the directory :)

## Resources

- [login1 dbus interface](https://www.freedesktop.org/software/systemd/man/org.freedesktop.login1.html)
- [inhibitor API](https://www.freedesktop.org/wiki/Software/systemd/inhibit/)
- [stackoverflow post](https://stackoverflow.com/questions/33428804/role-of-mainloops-event-loops-in-dbus-service) on how dbus-python integrates with a mainloop
- [intro to dbus](https://www.freedesktop.org/wiki/IntroductionToDBus/)
- This [stackoverflow post](https://unix.stackexchange.com/questions/337853/how-can-i-trigger-a-systemd-unit-on-suspend-before-networking-is-shut-down) where the poster explains why a pure systemd service solution doesn't work and provides a repo with a working solution. I started with their code and adapted it to my specific use case
- [Stackoverflow post](https://unix.stackexchange.com/questions/152039/how-to-run-a-user-script-after-systemd-wakeup) on why a user service would not work
