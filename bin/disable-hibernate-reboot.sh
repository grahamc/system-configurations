#!/bin/bash

if [ -f /etc/systemd/sleep.conf.bak ] && [ $1 == "post" ] && [ $2 == "hibernate" ]; then
  sudo mv -f /etc/systemd/sleep.conf.bak /etc/systemd/sleep.conf
fi
