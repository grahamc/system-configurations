#!/usr/bin/env sh

# NetworkManager turns off after receiving a dbus message, outside of systemd's
# scheduling, so to make sure my speakers are turned off before NetworkManager
# shuts down, I turn off my speakers here.
sudo systemctl stop smart-plug.service
