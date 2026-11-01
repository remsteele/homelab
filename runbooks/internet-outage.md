# Internet outage or intentional WAN shutoff

Use this when Cox is down or Internet usage must stop while retaining local
services.

## Disable WAN

Preferred method:

1. In OPNsense, open **Interfaces -> WAN**.
2. Clear **Enable interface**.
3. Save and apply.

Physical fallback: disconnect the Cox Ethernet cable feeding `enp3s0f0`.

Expected local availability includes Proxmox, OPNsense, Unbound, Caddy,
Jellyfin, the Arr stack, and eventually DVD streaming. Public certificate
renewal, indexers, DDNS, metadata, and Proton connectivity require Internet.

## Restore WAN

1. Re-enable WAN or reconnect the Cox feed.
2. Confirm OPNsense has an IPv4 lease and can resolve through Unbound.
3. Confirm Cloudflare DDNS updates `terraria.rvsteele.com` if the address changed.
4. Check CT 102:

```sh
pct exec 102 -- cat /etc/resolv.conf
pct exec 102 -- systemctl status wg-quick@proton --no-pager
pct exec 102 -- wg show proton
pct exec 102 -- systemctl status qbittorrent --no-pager
```

Expected resolver:

```text
search home.rvsteele.com
nameserver 10.0.40.1
```

If WireGuard failed with `Nexthop has invalid gateway`, confirm CT 102 has
`10.0.40.11`, a route via `10.0.40.1`, and working DNS, then restart WireGuard:

```sh
pct exec 102 -- ip -br address show eth0
pct exec 102 -- ip route
pct exec 102 -- systemctl restart wg-quick@proton
pct exec 102 -- systemctl start qbittorrent
```

Do not manually start qBittorrent without the tunnel or relax its OPNsense
block. Follow `runbooks/qbittorrent-vpn.md` for leak checks.

