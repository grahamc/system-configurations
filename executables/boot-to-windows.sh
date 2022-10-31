#!/bin/bash

sudo /home/biggs/bin/enable-hibernate-reboot.sh
cp /boot/efi/loader/windows-loader.conf.template /boot/efi/loader/loader.conf
systemctl hibernate
