# OPNsense recovery and validation

## Console password recovery

Use the VM console and select Single User mode. Then run:

```sh
/sbin/mount -u /
/sbin/zfs mount -a
opnsense-shell password
reboot
```

Choose a new value according to the password-manager policy. Never record it in
this repository or in a snapshot.

## After recovery

Verify from HOME:

- Direct GUI: `https://10.0.10.1`
- Proxied GUI: `https://router.home.rvsteele.com`
- Unbound on TCP/UDP 53
- DHCP on each active VLAN
- WAN lease and Internet access
- Terraria TCP 7777 port forward
- qBittorrent endpoint allow/block ordering

Confirm `router.home.rvsteele.com` remains an Alternate Hostname and that no
temporary WAN WebGUI rule exists.

## Memory investigation

Do not diagnose OOM from the Proxmox graph alone; FreeBSD cache accounting can
look nearly full. Use inside OPNsense:

```sh
top -o res
swapinfo -h
```

Review active/wired/ARC/free and swap together.

