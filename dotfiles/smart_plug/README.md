# Smart Plug Controller

This project contains:

- A script to turn a Kasa smart plug on and off.

- A [systemd](https://systemd.io/) service to automatically turn it on after the computer starts
  up or is woken up and turn it off before the computer suspends, hibernates, restarts, or shuts
  down. (**TODO:** Need to document this)

- A macOS tray icon to turn the plug on and off. (**TODO:** Need to document this)

## Why

If you leave studio monitors on while turning off the sound source, you will get a loud POP
noise, which
[isn't good for the speakers](https://www.sweetwater.com/insync/power-power-off-sequence/).

## Requirements

- [nix](https://nixos.org/) -- For dependencies. See the README at the root of this repository for
  installation instructions.
- direnv -- To manage the development environment
- A Kasa smart plug with the alias 'plug'

## Run

- Run `python smart_plug.py on/off` in this directory. If you don't pass an argument, it
  exits with `0` if the plug is on, `1` if it's off, and `2` if there was an error.

## Development

- direnv will automatically set up the development environment when you enter this directory
  and remove when you leave.

## Resources

- [login1 dbus interface](https://www.freedesktop.org/software/systemd/man/org.freedesktop.login1.html)
- [inhibitor API](https://www.freedesktop.org/wiki/Software/systemd/inhibit/)
- [stackoverflow post](https://stackoverflow.com/questions/33428804/role-of-mainloops-event-loops-in-dbus-service) on how dbus-python integrates with a mainloop
- [intro to dbus](https://www.freedesktop.org/wiki/IntroductionToDBus/)
- This [stackoverflow post](https://unix.stackexchange.com/questions/337853/how-can-i-trigger-a-systemd-unit-on-suspend-before-networking-is-shut-down) where the poster explains why a pure systemd service solution doesn't work and provides a repo with a working solution. I started with their code and adapted it to my specific use case
- [Stackoverflow post](https://unix.stackexchange.com/questions/152039/how-to-run-a-user-script-after-systemd-wakeup) on why a user service would not work
