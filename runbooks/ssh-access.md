# SSH access and audit

The homelab key pair lives on the owner's MacBook:

- Private key: `~/.ssh/homelab_ed25519`
- Public key: `~/.ssh/homelab_ed25519.pub`
- Ed25519 fingerprint: `SHA256:KxOez4FB3HfcyKBI5GHXEHuhyqrP8LPxbX2NESIgdF0`

Only the public key is installed on remote systems. Never copy the private key
into this repository, a VM/container, a snapshot, or a prompt.

## Current accounts

| Host | Address | SSH account | Verified posture |
|---|---|---|---|
| OPNsense | 10.0.10.1 | `remington` | Public-key only is advertised, but the documented key was rejected on 2026-11-02; repair required |
| Proxmox | 10.0.10.2 | `root` | Root key and password login currently allowed |
| Caddy | 10.0.10.3 | `root` | Root key-only; passwords enabled globally |
| AdGuard Home | 10.0.10.4 | `root` | Root key-only; passwords enabled globally |
| Homepage | 10.0.10.5 | `root` | Root key-only; passwords enabled globally |
| Uptime Kuma | 10.0.10.6 | `root` | Root key-only; passwords enabled globally |
| Jellyfin | 10.0.40.10 | `root` | Root key-only; passwords enabled globally |
| qBittorrent | 10.0.40.11 | `root` | Root key-only; passwords enabled globally |
| Sonarr | 10.0.40.12 | `root` | Root key-only; passwords enabled globally |
| Radarr | 10.0.40.13 | `root` | Root key-only; passwords enabled globally |
| Prowlarr | 10.0.40.14 | `root` | Root key-only; passwords enabled globally |
| DVDStream | 10.0.40.15 | `root` | User-reported key installed; host is off |
| Games | 10.0.50.10 | `remington` | Key works; password auth is also advertised |

The EAP650 refuses TCP 22 and is not SSH-managed.

Example:

```sh
ssh router
ssh pve
```

The OPNsense example is the desired command, not a currently working access
claim. Repair the user's authorized key through the Web UI or console while
preserving the working API and console recovery paths.

## MacBook SSH aliases

`~/.ssh/config` maps short names and web FQDNs directly to each host's real
backend address. All homelab entries use `~/.ssh/homelab_ed25519`, public-key
authentication, and `IdentitiesOnly yes`; the file is mode `0600`.

| Command | Destination | User | Additional aliases |
|---|---|---|---|
| `ssh router` | `10.0.10.1` | `remington` | `opnsense`, `router.home.rvsteele.com` |
| `ssh pve` | `10.0.10.2` | `root` | `proxmox`, `pve.home.rvsteele.com` |
| `ssh caddy` | `10.0.10.3` | `root` | — |
| `ssh adguard` | `10.0.10.4` | `root` | `adguard.home.rvsteele.com` |
| `ssh homepage` | `10.0.10.5` | `root` | `homepage.home.rvsteele.com` |
| `ssh uptime` | `10.0.10.6` | `root` | `uptime-kuma`, `uptime.home.rvsteele.com` |
| `ssh jellyfin` | `10.0.40.10` | `root` | `jellyfin.home.rvsteele.com` |
| `ssh qbittorrent` | `10.0.40.11` | `root` | `qbit`, `qbittorrent.home.rvsteele.com` |
| `ssh sonarr` | `10.0.40.12` | `root` | `sonarr.home.rvsteele.com` |
| `ssh radarr` | `10.0.40.13` | `root` | `radarr.home.rvsteele.com` |
| `ssh prowlarr` | `10.0.40.14` | `root` | `prowlarr.home.rvsteele.com` |
| `ssh dvdstream` | `10.0.40.15` | `root` | Host intentionally stopped |
| `ssh games` | `10.0.50.10` | `remington` | `terraria`, `terraria.home.rvsteele.com` |

The FQDN aliases intentionally override normal DNS resolution for SSH. Web
names usually resolve to Caddy at `10.0.10.3`, while SSH must reach the backend
host itself.

## Read-only agent use

For inventory, use `BatchMode=yes` and run only explicit diagnostic commands.
Do not grant blanket passwordless sudo. OPNsense currently requires the
`remington` password for sudo, which prevented live PF/NAT export during the
2026-11-01 audit. If repeatable privileged discovery is desired, prefer a
root-owned, fixed-output audit script with a narrowly scoped sudo rule instead
of unrestricted command execution.

## Hardening priorities

1. Proxmox currently permits root password SSH and should be addressed first.
2. Confirm whether the extra RSA `root@pve` authorized key is still needed.
3. Decide whether password fallback on Debian guests is intentional.
4. Before disabling any path, verify console access and a second working admin
   session so a mistake cannot lock out management.

