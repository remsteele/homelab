#!/bin/sh
# Read-only OPNsense evidence collection. This script does not change state.

printf '=== BASE ===\n'
id
opnsense-version -a 2>/dev/null || opnsense-version 2>/dev/null
uname -a
ifconfig -a
netstat -rn
sockstat -46l

printf '=== SSH USER KEY ===\n'
ssh-keygen -lf /home/remington/.ssh/authorized_keys 2>/dev/null

printf '=== SSH EFFECTIVE ===\n'
(sudo -n /usr/sbin/sshd -T 2>/dev/null || /usr/sbin/sshd -T 2>/dev/null) |
  grep -E '^(passwordauthentication|permitrootlogin|pubkeyauthentication|kbdinteractiveauthentication|allowusers|allowgroups) '

printf '=== PF RULES ===\n'
sudo -n /sbin/pfctl -sr -v 2>&1

printf '=== NAT ===\n'
sudo -n /sbin/pfctl -sn 2>&1

printf '=== ALIASES ===\n'
sudo -n /sbin/pfctl -t LOCAL_NETS -T show 2>&1
sudo -n /sbin/pfctl -t PROTON_ENDPOINT -T show 2>&1

printf '=== DNS/DHCP GENERATED ===\n'
sudo -n grep -R -h -E \
  '^(server:|interface:|port:|host-record=|dhcp-range=|dhcp-host=|local-data:)' \
  /var/etc/unbound /usr/local/etc/dnsmasq.conf /var/etc/dnsmasq* \
  2>/dev/null | head -n 500

printf '=== PACKAGES ===\n'
opnsense-version -v 2>/dev/null
pkg info 2>/dev/null | grep -Ei 'opnsense|zenarmor|sensei|ddclient|dnsmasq'

printf '=== CONFIGCTL READ ACTIONS ===\n'
configctl -l 2>/dev/null |
  grep -Ei 'filter|firewall|unbound|dnsmasq|dhcp|zenarmor' |
  head -n 200
configctl filter list 2>&1
configctl unbound status 2>&1
configctl dnsmasq status 2>&1

printf '=== ZENARMOR PROCESSES ===\n'
ps auxww | grep -Ei 'zenarmor|sensei|eastpect' | grep -v grep

printf '=== DNS FILE LOCATIONS ===\n'
find /var/etc /usr/local/etc -maxdepth 3 -type f \
  \( -iname '*dnsmasq*' -o -iname '*unbound*' \) -ls \
  2>/dev/null | head -n 200

printf '=== UNBOUND HOME DOMAIN REFERENCES ===\n'
ps auxww | grep '[u]nbound'
ls -la /var/unbound /var/etc/unbound 2>/dev/null
grep -R -n 'home.rvsteele.com' \
  /var/unbound /var/etc/unbound /usr/local/etc/unbound \
  2>/dev/null | head -n 300
