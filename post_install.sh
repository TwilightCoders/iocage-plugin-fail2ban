#!/bin/sh

pkg update -y
pkg upgrade -y

# Install again for latest.
# https://www.ixsystems.com/community/threads/freenas-fail2ban-for-ssh-block-using-hosts-allow.61231/
pkg install -y security/py-fail2ban

# Enable the service
sysrc -f /etc/rc.conf fail2ban_enable="YES"

mkdir -p /mnt/log/root

# Set bash as shell
chsh -s /usr/local/bin/bash root

# Start the service
service fail2ban start 2>/dev/null
