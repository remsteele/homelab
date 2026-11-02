# Service endpoints

Generated from `data/services.yaml` by `tools/generate_docs.rb`. Do not edit by hand.

| Service | Host | Listener | User URL / public endpoint | Availability | State |
|---|---|---|---|---|---|
| opnsense-api | router | HTTPS 10.0.10.1:443 | — | — | confirmed |
| opnsense-webgui | router | HTTPS 10.0.10.1:443 | https://router.home.rvsteele.com<br>https://10.0.10.1 | — | confirmed |
| proxmox-webgui | pve | HTTPS 10.0.10.2:8006 | https://pve.home.rvsteele.com<br>https://10.0.10.2:8006 | — | confirmed |
| eap-webui | eap650 | HTTPS 10.0.10.111:443 | https://ap.home.rvsteele.com<br>https://10.0.10.111 | — | confirmed |
| caddy | caddy |  | — | — | confirmed |
| adguard-home | adguard | TCP/UDP 10.0.10.4:53<br>HTTP 10.0.10.4:80 | https://adguard.home.rvsteele.com | — | confirmed |
| homepage | homepage | HTTP 10.0.10.5:3000 | https://homepage.home.rvsteele.com | — | confirmed |
| uptime-kuma | uptime-kuma | HTTP 10.0.10.6:3001 | https://uptime.home.rvsteele.com | — | confirmed |
| jellyfin | jellyfin | HTTP 10.0.40.10:8096 | https://jellyfin.home.rvsteele.com | — | confirmed |
| qbittorrent | qbittorrent | HTTP 10.0.40.11:8080 | https://qbittorrent.home.rvsteele.com | — | confirmed |
| proton-wireguard | qbittorrent |  | — | — | confirmed |
| sonarr | sonarr | HTTP 10.0.40.12:8989 | https://sonarr.home.rvsteele.com | — | confirmed |
| radarr | radarr | HTTP 10.0.40.13:7878 | https://radarr.home.rvsteele.com | — | confirmed |
| prowlarr | prowlarr | HTTP 10.0.40.14:9696 | https://prowlarr.home.rvsteele.com | — | confirmed |
| flaresolverr | prowlarr | HTTP 127.0.0.1:8191 | — | — | confirmed |
| terraria | games | TCP 10.0.50.10:7777 | terraria.rvsteele.com:7777 | — | confirmed |
| dvd-inspection | dvdstream |  | — | unavailable | confirmed |
| dvd-watch-now | dvdstream |  | https://dvd.home.rvsteele.com | unavailable-host-stopped | planned |
| lg-tv-root-ui | lg-c3 | HTTP 10.0.20.134:8080<br>SSH 10.0.20.134:22<br>Telnet 10.0.20.134:23 | https://tv.home.rvsteele.com | — | confirmed |
| zenarmor | router |  | — | — | confirmed |
