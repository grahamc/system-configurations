#!/bin/bash

if [ -f /etc/systemd/sleep.conf ]; then
    mv /etc/systemd/sleep.conf /etc/systemd/sleep.conf.bak
fi
printf "[Sleep]\nHibernateMode=reboot\n" | tee /etc/systemd/sleep.conf
