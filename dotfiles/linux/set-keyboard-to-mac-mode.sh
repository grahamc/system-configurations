#!/usr/bin/env sh

# source:
# https://unix.stackexchange.com/questions/121395/on-an-apple-keyboard-under-linux-how-do-i-make-the-function-keys-work-without-t
#
# TODO: Why does macOS respect the mode set directly through my keyboard, but Linux doesn't?

echo '1' | sudo tee /sys/module/hid_apple/parameters/fnmode

echo options hid_apple fnmode=1 | sudo tee -a /etc/modprobe.d/hid_apple.conf
sudo update-initramfs -u -k all

