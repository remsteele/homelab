# Topology and trust boundaries

This is a readable view of `data/networks.yaml`, `data/firewall.yaml`, and
`data/connections.yaml`. The YAML remains authoritative.

```text
Internet
   |
Cox gateway (bridge mode; management historically 192.168.0.1)
   |
pve enp3s0f0 -- vmbr0 -- OPNsense VM 100 vtnet0 (WAN DHCP)
                              |
                         vtnet1 trunk
                              |
                         pve vmbr1
                              |
                  pve enp3s0f1 -- EAP650
                              |
        +----------+----------+----------+----------+
        |          |          |          |          |
   VLAN 10     VLAN 20    VLAN 30    VLAN 40    VLAN 50
    HOME         IOT        GUEST      SERVERS      DMZ
 10.0.10/24  10.0.20/24 10.0.30/24 10.0.40/24 10.0.50/24
 trusted     untrusted   untrusted   restricted   restricted
```

The Proxmox host is addressed only on `vmbr1.10` at `10.0.10.2/24` with
gateway `10.0.10.1`. It must not have an IP or default gateway on WAN bridge
`vmbr0`.

## Trust policy

HOME currently has broad access and can initiate toward SERVERS, DMZ, and the
Internet. IOT, GUEST, SERVERS, and DMZ may query OPNsense DNS, are blocked from
initiating toward RFC1918 networks, and then may access the Internet. Stateful
replies to HOME-initiated sessions remain allowed. An explicit IOT-to-Jellyfin
exception supports the TV if it resides on IOT.

qBittorrent is a host-specific exception within SERVERS. Before generic rules,
it may query OPNsense DNS and reach only the current Proton endpoint on UDP
51820; all other direct egress is blocked. Its torrent traffic uses the Proton
WireGuard interface. This ordering is safety-critical.

Services on the same VLAN 40 communicate through the virtual switch, not
OPNsense inter-VLAN policy. That includes Sonarr/Radarr/Prowlarr calls to
qBittorrent and one another.

## Name and TLS path

For most internal web names, Unbound returns `10.0.10.3`. Caddy terminates a
publicly trusted certificate obtained with Cloudflare DNS-01 and proxies to the
actual backend. No WAN 80/443 exposure is required. Terraria is intentionally
different: its internal name points directly to `10.0.50.10`, while the public
DNS-only Cloudflare A record follows the dynamic WAN address and OPNsense
forwards TCP 7777.

AdGuard Home is deployed in CT 109 at `10.0.10.4`. It filters client queries,
uses Cloudflare DNS-over-HTTPS for public names, and sends
`home.rvsteele.com` plus private reverse lookups to OPNsense Unbound. Its own
UI name is rewritten to Caddy at `10.0.10.3`. Client DHCP distribution and the
required non-HOME VLAN firewall exceptions remain staged, so OPNsense is still
the resolver delivered to most clients.

Homepage (CT 110, `10.0.10.5`) and Uptime Kuma (CT 111, `10.0.10.6`) are on
HOME. Caddy serves their browser names, while Uptime Kuma probes backend IPs
directly across HOME, SERVERS, and DMZ. This placement uses HOME's existing
trusted access and avoids a broad monitoring exception from a restricted VLAN.
Neither container mounts the media disk.

## Media data path

```text
/mnt/media on pve
      |
      +-- /media in qBittorrent -> downloads/{movies,tv}
      +-- /media in Radarr      -> hardlinks into movies
      +-- /media in Sonarr      -> hardlinks into tv
      +-- /media in Jellyfin    -> reads movies and tv
```

One ext4 filesystem enables atomic moves and hardlinks. The shared container
group is `media` GID 5000, mapped to host GID 105000. Jellyfin is intentionally
not a writable group member.

## Planned paths

VLAN 60 and a Tor gateway are not deployed. VLAN 99 management is not deployed.
DVD Watch Now is also planned: physical drive -> CT 108 -> FFmpeg/HLS -> Caddy
-> LG C3. The current blocker is the optical SATA link, not the web stack.

