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
| OPNsense | 10.0.10.1 | `remington` | Public-key only; root login user-confirmed disabled |
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
ssh -i ~/.ssh/homelab_ed25519 remington@10.0.10.1
ssh -i ~/.ssh/homelab_ed25519 root@10.0.10.2
```

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

