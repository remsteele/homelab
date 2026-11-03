# Homepage and Uptime Kuma

Homepage and Uptime Kuma run in separate unprivileged Proxmox LXCs on the
trusted HOME VLAN. Neither container has a media-disk mount, and neither
service is intended for WAN exposure.

| Service | LXC | Backend | HTTPS name | Image |
|---|---:|---|---|---|
| Homepage | 110 | `10.0.10.5:3000` | `https://homepage.home.rvsteele.com` | `ghcr.io/gethomepage/homepage:v2.7.0` |
| Uptime Kuma | 111 | `10.0.10.6:3001` | `https://uptime.home.rvsteele.com` | `louislam/uptime-kuma:2.5.8` |

Both LXCs are Debian 13, use Docker Compose from the Debian repository, have
`onboot=1`, and use `restart: unless-stopped`. Their static addresses are in
the Proxmox LXC definitions. Caddy terminates HTTPS at `10.0.10.3`.

## Credentials

- Homepage's randomized login password is the macOS Keychain generic password
  with service `homepage.home.rvsteele.com`, account `remington`. Homepage's
  separate cookie secret uses service `homepage-auth-secret`, account
  `homepage`.
- Uptime Kuma's administrator is `remington`. Its randomized password is the
  macOS Keychain generic password with service `uptime.home.rvsteele.com`,
  account `remington`.

Do not copy these values into this repository, a snapshot, or a command log.
Homepage receives its two secrets from `/opt/homepage/.env`, which must remain
mode `0600`. Uptime Kuma stores only its password hash in its local database.

## OPNsense DNS state

These rows are present under **Services -> Dnsmasq DNS & DHCP -> Hosts** and
were confirmed through the authenticated API on 2026-11-02:

| Host | Domain | IP address | Hardware address | Description |
|---|---|---|---|---|
| `homepage` | `home.rvsteele.com` | `10.0.10.5` | `BC:24:11:A3:FA:7D` | `Homepage` |
| `uptime-kuma` | `home.rvsteele.com` | `10.0.10.6` | `BC:24:11:9F:A1:9B` | `Uptime Kuma` |

These rows inventory and reserve each backend identity; they do not replace
the Caddy-facing web records. These OPNsense Unbound host overrides are also
present and were confirmed through the API on 2026-11-02:

```text
homepage.home.rvsteele.com  A  10.0.10.3
uptime.home.rvsteele.com    A  10.0.10.3
```

Homepage's same-HOME paths are switched without crossing OPNsense. Uptime Kuma
has exact OPNsense HOME rules for router TCP 443, each monitored SERVERS port,
and Terraria TCP 7777. Do not replace those with a broad cross-VLAN exception.
AdGuard also has both Caddy rewrites pointing to `10.0.10.3`.

Verify the two resolver paths separately:

```sh
dig +short @10.0.10.1 homepage.home.rvsteele.com A
dig +short @10.0.10.1 uptime.home.rvsteele.com A
dig +short @10.0.10.4 homepage.home.rvsteele.com A
dig +short @10.0.10.4 uptime.home.rvsteele.com A
```

All four results should be `10.0.10.3`.

## Homepage operations

The Compose project and configuration are under `/opt/homepage`. Homepage
uses its built-in password gate and an explicit allowed-host list. It does not
mount `/var/run/docker.sock`; service links are maintained explicitly in
`/opt/homepage/config/services.yaml`.

```sh
ssh -i ~/.ssh/homelab_ed25519 root@10.0.10.5
cd /opt/homepage
docker compose ps
docker compose logs --tail 100
curl -fsS http://10.0.10.5:3000/api/healthcheck
```

After editing configuration, run `docker compose config --quiet`, then
`docker compose up -d`. Preserve the `.env` ownership and mode.

The Infrastructure group includes the rooted LG TV link at
`https://tv.home.rvsteele.com`. Its six services use a six-column desktop row;
the TV tile uses the `mdi-television` icon. The Media group uses a six-column
row and includes Seerr at `https://seerr.home.rvsteele.com`.

## Uptime Kuma operations

The Compose project is `/opt/uptime-kuma`; persistent data is
`/opt/uptime-kuma/data`. SQLite is intentionally on the local LXC root disk so
its locking semantics do not depend on a network filesystem.

The monitor set checks Homepage, OPNsense, Proxmox, AdGuard Home, Jellyfin,
qBittorrent, Sonarr, Radarr, Prowlarr, Seerr, and Terraria every 60 seconds,
with two retries. Seerr uses `/api/v1/status` rather than the login page. No
outbound notification provider is configured yet.

```sh
ssh -i ~/.ssh/homelab_ed25519 root@10.0.10.6
cd /opt/uptime-kuma
docker compose ps
docker compose logs --tail 100
```

OPNsense and Proxmox are monitored by direct IP and must ignore their
self-signed backend certificates. Browser access should still use Caddy and a
valid public certificate.

## Backup, upgrade, and recovery

Before upgrading either service, back up its entire `/opt` application
directory outside the LXC. Stop Uptime Kuma before copying its SQLite data:

```sh
cd /opt/uptime-kuma
docker compose down
# Copy /opt/uptime-kuma to protected backup storage.
docker compose up -d
```

Pin a reviewed image version in `compose.yaml`; do not switch to an unbounded
`latest` tag. Pull, recreate, read the logs, test HTTPS and authentication,
then reboot the LXC to verify persistence. If an upgrade fails, restore the
saved Compose project and data directory and start the previous pinned image.

For Caddy changes, follow `runbooks/caddy.md`: back up the Caddyfile, validate
the candidate, reload, and test with `curl --resolve`. WebSocket proxying for
Uptime Kuma works through Caddy's normal `reverse_proxy` handling.
