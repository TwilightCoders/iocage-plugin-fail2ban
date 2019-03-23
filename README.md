# iocage-plugin/fail2ban
Sets up [Fail2Ban](fail2ban.org) for FreeBSD systems (including FreeNAS).

Overall, this plugin brings the meaningful settings into visibility by leveraging the jail overlay ability, so only the files that you probably want to edit and only the settings you probably care about are present here.

Explore the tree and most of the modifications you may want to make should be fairly apparent.

## Installation

Check out this repository:

`git clone git@github.com:TwilightCoders/iocage-plugin-fail2ban.git`

Install with `iocage` from within the project directory:
- `iocage fetch -P -n fail2ban.json ip4_addr="[interface]|[ip_address]/[cidr]"`
- e.g. `iocage fetch -P -n fail2ban.json ip4_addr="em0|192.168.0.111/24"`

## Configuration

Stop the jail:
`iocage stop fail2ban`

### Logs
Mount your root log directory (read only recommended):

`auth.log` for SSH:
- `iocage fstab -a fail2ban /var/log /mnt/log/root nullfs ro 0 0`

### Settings
You can read more about fail2ban configuration by referencing [the man pages "fail2ban-jail(5)"](https://www.freebsd.org/cgi/man.cgi?query=fail2ban-jail.conf&manpath=FreeBSD+12.0-RELEASE+and+Ports)

Mount global fail2ban config directory (readonly recommended, but not required):
- `iocage fstab -a fail2ban /path/to/dataset/for/fail2ban/global/conf /usr/local/etc/fail2ban/fail2ban.d nullfs ro 0 0`
- e.g. `iocage fstab -a fail2ban /mnt/raid1/data/fail2ban/global /usr/local/etc/fail2ban/fail2ban.d nullfs ro 0 0`

Example `fail2ban.conf` to go in `/path/to/dataset/for/fail2ban/global/conf`:
```sh
[Definition]

# Option: logtarget
# Notes.: Set the log target. This could be a file, SYSLOG, STDERR or STDOUT.
#         Only one log target can be specified.
#         If you change logtarget from the default value and you are
#         using logrotate -- also adjust or disable rotation in the
#         corresponding configuration file
#         (e.g. /etc/logrotate.d/fail2ban on Debian systems)
# Values: [ STDOUT | STDERR | SYSLOG | SYSOUT | FILE ]  Default: STDERR
#
logtarget = /var/log/fail2ban.log
```

Mount jail configurations (fail2ban calls the enabled filter/action combos 'jails', not to be confused with FreeBSD jails):
- `iocage fstab -a fail2ban /path/to/dataset/for/fail2ban/jail/conf /usr/local/etc/fail2ban/fail2ban.d nullfs ro 0 0`
- e.g. `iocage fstab -a fail2ban /mnt/raid1/data/fail2ban/jails /usr/local/etc/fail2ban/jail.d nullfs ro 0 0`

### SSH
SSH is a common service to monitor for banning IPs from botnet bruteforce attempts.

#### Mounts
Mount the directory where the `hosts.evil` file will be written to (outside of the jail) for persistant storage.
- `iocage fstab -a fail2ban /path/to/dataset/for/jail/hosts /usr/local/etc/hosts nullfs rw 0 0`
- e.g. `iocage fstab -a fail2ban /mnt/raid1/data/fail2ban/etc /usr/local/etc/hosts nullfs rw 0 0`

#### Config
Example "jail config" (`sshd.conf`) to go in `/path/to/dataset/for/fail2ban/jail/conf`
```sh
# sshd.conf
[DEFAULT]

# "ignoreip" can be a list of IP addresses, CIDR masks or DNS hosts. Fail2ban
# will not ban a host which matches an address in this list. Several addresses
# can be defined using space (and/or comma) separator.
ignoreip = 127.0.0.1/8 ::1 192.168.0.0/24

# "bantime" is the number of seconds that a host is banned.
bantime  = 750h

# "mode" defines the mode of the filter (see corresponding filter implementation for more info).
mode = normal

# "filter" defines the filter to use by the jail.
#  By default jails have names matching their filter name
#
filter = %(__name__)s[mode=%(mode)s]

#
# SSH servers
#

[sshd]

# To use more aggressive sshd modes set filter parameter "mode" in jail.local:
# normal (default), ddos, extra or aggressive (combines all).
# See "tests/files/logs/sshd" or "filter.d/sshd.conf" for usage example and details.
enabled = true
mode   = normal
port	= ssh
logpath = /mnt/log/root/auth.log
bantime  = 750h
maxretry = 3
findtime = 20m
backend = %(sshd_backend)s
action = hostsdeny
```

Update the host's `hosts.allow` (add above `ALL : ALL : allow`):

```sh
# enable fail2ban
sshd : /path/to/dataset/for/jail/hosts/hosts.evil : deny
```

e.g.

```sh
# enable fail2ban
sshd : /mnt/raid1/data/fail2ban/etc/hosts.evil : deny

# Start by allowing everything (this prevents the rest of the file
# from working, so remove it when you need protection).
# The rules here work on a "First match wins" basis.
ALL : ALL : allow
```

Note, if you're on `FreeNAS` you'll want to edit /conf/base/etc/hosts.allow to make changes persistent across reboots. Ensure it works the way you intended by first editing `/etc/hosts.allow` before editing the base config.

## Contributions
Source for the original distillation of instructions found here came from [onthax](https://www.ixsystems.com/community/threads/freenas-fail2ban-for-ssh-block-using-hosts-allow.61231)

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/TwilightCoders/iocage-plugin-fail2ban.

## License
Released under the [MIT License](http://opensource.org/licenses/MIT).
