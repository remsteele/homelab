# Seerr request portal

Seerr runs in unprivileged CT 112 at `10.0.40.16` on the SERVERS VLAN. Caddy
publishes it internally as `https://seerr.home.rvsteele.com`; it has no direct
WAN exposure and no media-disk mount. It uses APIs to authenticate against
Jellyfin and submit approved requests to Sonarr or Radarr.

## Current integration

| System | Endpoint | Purpose | Selected settings |
|---|---|---|---|
| Jellyfin | `http://10.0.40.10:8096` | Login and library discovery | Movies and Shows enabled |
| Sonarr | `http://10.0.40.12:8989` | TV requests | `/media/tv`, `HD-1080p`, season folders enabled |
| Radarr | `http://10.0.40.13:7878` | Movie requests | `/media/movies`, `HD-1080p`, minimum availability `released` |

Sonarr and Radarr are the default request servers, synchronization and
automatic searching are enabled, and their external links use the internal
HTTPS names. A request can therefore start a download; do not create a test
request unless that side effect is intended.

## Runtime and configuration

The Compose project is `/opt/seerr`. The pinned image is
`ghcr.io/seerr-team/seerr:v3.5.1`, and persistent application data is bind
mounted from `/opt/seerr/config` to `/app/config`.

```sh
ssh seerr
cd /opt/seerr
docker compose ps
docker compose logs --tail 100
curl -fsS http://10.0.40.16:5055/api/v1/status
```

`/opt/seerr/config/settings.json` contains API keys and integration
credentials. Never print it, copy it into this repository, or include it in a
snapshot. The service-level API key may be used for a narrow diagnostic call
on the host, but output must be filtered to exclude keys and credentials.

## Network dependencies

- OPNsense Dnsmasq inventories `seerr.home.rvsteele.com` at `10.0.40.16` with
  MAC `BC:24:11:46:62:2D`.
- OPNsense Unbound and AdGuard both return `10.0.10.3` for the web name so
  clients use Caddy.
- Exact HOME rules allow Caddy `10.0.10.3` and Uptime Kuma `10.0.10.6` to TCP
  5055. Generic HOME clients remain blocked from reaching the backend across
  VLANs.
- Seerr, Jellyfin, Sonarr, and Radarr share the SERVERS VLAN, so their API
  traffic is switched locally rather than routed through OPNsense.

## Verify

```sh
dig +short @10.0.10.1 seerr.home.rvsteele.com A
dig +short @10.0.10.4 seerr.home.rvsteele.com A
curl -I https://seerr.home.rvsteele.com
ssh caddy 'nc -zvw3 10.0.40.16 5055'
ssh uptime-kuma 'nc -zvw3 10.0.40.16 5055'
```

Both DNS queries should return `10.0.10.3`. HTTPS normally redirects to the
login flow. The container health check and Uptime Kuma monitor both use
`/api/v1/status`.

## Backup, upgrade, and rollback

Back up `/opt/seerr/compose.yaml` and `/opt/seerr/config` to protected storage
before an upgrade. Stop the container for a consistent application database
copy. Review and pin a specific version; do not switch to an unbounded tag.

```sh
cd /opt/seerr
docker compose down
# Copy /opt/seerr to protected backup storage without exposing settings.json.
docker compose pull
docker compose up -d
docker compose ps
```

Verify the direct status endpoint, integrations, HTTPS, and a controlled LXC
reboot. Roll back by restoring the saved Compose project and config directory,
then starting the previously pinned image.
