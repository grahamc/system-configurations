#!/bin/sh

# I tried to run this command in home-manager, but it failed with exit code 2
# which, according to the manpage, means it couldn't find a file. I think this
# is because home-manager doesn't run as the current user so it can't find the
# .desktop file linked in ~/.local/share/applications

xdg-settings set default-web-browser my-firefox.desktop