# qBittorrent and ProtonVPN

The desired outcome is fail-closed torrenting: if Proton is unavailable,
qBittorrent must not use normal WAN egress.

## Healthy-state checks

Run from Proxmox or inside CT 102 as appropriate:

```sh
pct exec 102 -- ip -br address show eth0 proton
pct exec 102 -- ip route
pct exec 102 -- wg show proton
pct exec 102 -- systemctl status wg-quick@proton --no-pager
pct exec 102 -- systemctl status qbittorrent --no-pager
pct exec 102 -- getent hosts protonvpn.com
```

Confirm:

- `eth0` owns `10.0.40.11`.
- `proton` exists, has a recent handshake, and transfers counters move.
- qBittorrent is bound to network interface `proton` in its advanced settings.
- `/etc/resolv.conf` uses `10.0.40.1`, not `192.168.0.1`.
- `10.0.10.0/24` routes via `10.0.40.1 dev eth0`.
- Caddy can still reach the WebUI and replies return over `eth0`.

## Firewall contract

The OPNsense SERVERS rules for source `10.0.40.11` must be ordered before the
generic SERVERS rules:

1. Permit TCP/UDP 53 to This Firewall.
2. Permit UDP 51820 to alias `PROTON_ENDPOINT`.
3. Block all other destinations.

Compare the current WireGuard endpoint with `PROTON_ENDPOINT` whenever the
provider configuration changes.

## Boot-race recovery

If `wg-quick@proton` reports `Nexthop has invalid gateway`, it ran its PostUp
route before DHCP finished. Verify the LAN address and gateway first, then:

```sh
systemctl restart wg-quick@proton
systemctl start qbittorrent
```

This is recovery, not the permanent fix. The permanent unit ordering must wait
for a genuinely usable `eth0`/DHCP route while preserving the dependency and
kill switch. Record that implementation and repeated reboot evidence before
marking the verification item complete.

## Deliberate failure test

This test changes connectivity. Announce it and ensure no important downloads
are active.

1. Record the current public egress address from inside CT 102.
2. Stop `wg-quick@proton` and confirm qBittorrent also stops or loses its bound
   interface.
3. Confirm arbitrary Internet IP/TCP and DNS-mediated HTTP from CT 102 cannot
   leave through normal WAN. DNS to OPNsense may still work by design.
4. Confirm OPNsense logs show the host-specific block for attempted egress.
5. Restore WireGuard, verify handshake, then restore qBittorrent.

Do not paste public-IP service output into long-lived source data; store it only
in a dated, sanitized test snapshot if needed.

## Configuration that must remain secret

`/etc/wireguard/proton.conf` may be documented by path and non-secret routes,
but never commit its private key or provider credentials.

