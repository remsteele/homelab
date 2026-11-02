# Caddy and internal HTTPS

Caddy is CT 104 at `10.0.10.3`. Internal Unbound overrides send most
`*.home.rvsteele.com` web names to it. Certificates use Cloudflare DNS-01, so
WAN ports 80/443 do not need to be exposed.

## Validate and reload

Inside CT 104:

```sh
caddy list-modules | grep dns.providers.cloudflare
caddy validate --config /etc/caddy/Caddyfile
systemctl reload caddy
systemctl status caddy --no-pager
journalctl -u caddy --since '10 minutes ago' --no-pager
```

The Cloudflare token file is `/etc/caddy/cloudflare_token`, expected
`root:caddy` mode `0640`. Never print or copy its value into a snapshot.

## Backend rules

- Plain HTTP: Jellyfin 8096, qBittorrent 8080, Sonarr 8989, Radarr 7878,
  Prowlarr 9696, AdGuard Home 80.
- Self-signed HTTPS: Proxmox 8006, OPNsense 443, EAP650 443. These use
  backend TLS verification bypass because the backend certificates are local;
  the client-facing certificate remains publicly trusted.

The EAP650 additionally requires a backend Host override. A proposed fix for
its blank post-login UI removes the three `X-Forwarded-*` headers documented in
`data/services.yaml`; do not mark it current until browser testing confirms it.

## Troubleshooting sequence

1. Resolve the public name from a HOME client; it should normally return
   `10.0.10.3`.
2. Test the backend directly from Caddy.
3. Validate the Caddyfile before reloading.
4. Test browser login, deep links, refresh, and WebSocket/API calls—not only a
   HEAD request. Sonarr/Radarr/Prowlarr returning 401 to HEAD is expected when
   authentication is enabled.
5. Review Caddy and browser developer-tool errors without exporting cookies or
   authorization headers.

