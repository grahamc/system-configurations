# Smart Plug

## Installation

Some of the dependencies in the Pipfile require some libraries to be installed on your system:

* pygobject: See their [getting started guide](https://pygobject.readthedocs.io/en/latest/getting_started.html) for what needs to be installed.
* dbus-python:
  * linux - `sudo apt-get install libdbus-glib-1-dev libdbus-1-dev`

## Setup

- Take a look at the `install` script

## Resources

- [login1 dbus interface](https://www.freedesktop.org/software/systemd/man/org.freedesktop.login1.html)
- [inhibitor API](https://www.freedesktop.org/wiki/Software/systemd/inhibit/)
- [stackoverflow post](https://stackoverflow.com/questions/33428804/role-of-mainloops-event-loops-in-dbus-service) on how dbus-python integrates with a mainloop
- [intro to dbus](https://www.freedesktop.org/wiki/IntroductionToDBus/)
- This [stackoverflow post](https://unix.stackexchange.com/questions/337853/how-can-i-trigger-a-systemd-unit-on-suspend-before-networking-is-shut-down) where the poster explains why a pure systemd service solution doesn't work and provides a repo with a working solution. I started with their code and adapted it to my specific use case
- [Stackoverflow post](https://unix.stackexchange.com/questions/152039/how-to-run-a-user-script-after-systemd-wakeup) on why a user service would not work

