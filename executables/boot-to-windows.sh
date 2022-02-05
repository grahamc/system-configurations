#!/bin/bash

sudo /home/bigolu/bin/enable-hibernate-reboot.sh
cp /boot/efi/loader/windows-loader.conf.template /boot/efi/loader/loader.conf
systemctl hibernate
