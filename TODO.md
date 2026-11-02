# Homelab TODO

This is the prioritized execution list for the homelab. The structured files
under `data/` remain authoritative; this page is a human-friendly view of the
work recorded in `data/issues.yaml`, `data/plans.yaml`, and
`data/verification.yaml`.

Versions and package counts below were observed during the read-only audit on
2026-11-02. Re-check available versions immediately before an upgrade. Do not
mark an item complete until the live result is verified and the corresponding
source-of-truth files and sanitized snapshot are updated.

## P0 — protect data

- [ ] Back up irreplaceable data from `/mnt/media` to known-good storage and
  verify the copies. The WDC disk still has 3,304 pending sectors even though
  SMART reports PASSED. Follow `runbooks/media-disk.md`.
- [ ] Replace the failing media disk, establish a clean SMART baseline, restore
  the data, and verify ownership, mounts, and Sonarr/Radarr hardlinks.
- [ ] Configure scheduled Proxmox backups. The 2026-11-02 audit found no backup
  jobs and no dedicated backup storage. Define destination, retention, offsite
  copy, alerting, and a tested restore procedure.

## P1 — security and updates

- [ ] Back up OPNsense configuration, review the release notes, and update from
  26.7.5 to the current 26.7 release. The audit reported 26.7.8 as available.
  Recheck routing, DNS/DHCP, Terraria NAT, and qBittorrent rule order afterward.
- [ ] Refresh Proxmox package metadata and apply the reviewed update set in a
  maintenance window after backups exist. The cached 2026-10-02 metadata showed
  182 upgrades, including `pve-manager` 9.2.2 to 9.2.21.
- [ ] Update Uptime Kuma from 2.5.8 to 2.5.9 or newer; 2.5.9 includes a security
  fix. Back up `/opt/uptime-kuma`, then verify all monitors and reboot
  persistence.
- [ ] Update Caddy from 2.11.6 to 2.11.7 or newer. Back up and validate the
  Caddyfile, then test every HTTPS hostname and WebSocket proxy.
- [ ] Update Jellyfin from 12.1.0 to 12.4 or newer after protecting its database
  and configuration; verify playback and media mounts.
- [ ] Update qBittorrent from 5.1.0 to 5.3.0 or newer while preserving the
  WireGuard dependency, HOME return route, and fail-closed behavior.
- [ ] Update Prowlarr from 2.6.5.5623 to 2.7.0.5723 or newer and verify its
  Sonarr, Radarr, and FlareSolverr integrations.
- [ ] Refresh and patch the Debian package sets on Caddy, Sonarr, Radarr, and
  Prowlarr. Their month-old caches showed 81–86 upgrades. Recheck Jellyfin,
  qBittorrent, and Games too; their zero counts came from stale September
  metadata.
- [ ] Repair `remington@10.0.10.1` SSH key access. OPNsense advertised
  public-key-only authentication but rejected the documented Ed25519 key on
  2026-11-02. Preserve console and API recovery access while fixing it.
- [ ] Install the homelab public key for `root` on the rooted LG TV, verify a
  second `ssh tv` session, then disable its unencrypted Telnet TCP 23 service.
  Confirm the persistent authorized-keys path for the installed webOS build;
  never copy the private key to the TV.
- [ ] Harden Proxmox SSH: establish and test a named administrator and console
  recovery path, identify the extra RSA root key, then disable root/password
  SSH if no required workflow depends on it.

## P2 — network hardening and reliability

- [ ] Determine whether anything still uses the untagged `192.168.1.0/24` LAN.
  If not, remove its DHCP, IPv6 router advertisements, addresses, and broad
  default LAN rules through a planned migration.
- [x] Replaced `TEMP - HOME allow all` on 2026-11-02 with exact DNS,
  MacBook administration, Caddy backend, Uptime Kuma, and Terraria rules,
  followed by a private-network block and Internet pass. The old rule remains
  disabled at the bottom as a temporary rollback path.
- [ ] Decide whether to enable and configure the Proxmox firewall. It is
  currently disabled, so guest `firewall=1` flags do not enforce an independent
  same-VLAN policy.
- [ ] Complete the AdGuard client rollout: add per-VLAN TCP/UDP 53 passes to
  `10.0.10.4` above `LOCAL_NETS` blocks, then change DHCP DNS one VLAN at a
  time. Keep qBittorrent on OPNsense DNS until separately leak-tested. Follow
  `runbooks/adguard-home.md`.
- [ ] Fix and repeatedly test the qBittorrent WireGuard boot race, then perform
  a deliberate tunnel-failure leak test. Tracker, peer, DNS, and general
  Internet traffic must all remain blocked when Proton is down.
- [ ] Decide whether a second filtering DNS resolver is warranted; the current
  single AdGuard instance is a network DNS availability risk after cutover.
- [ ] Verify Guest Wi-Fi client isolation on the EAP650.
- [ ] Recheck OPNsense interface output-error and send-queue-drop counters after
  a known interval. Input errors were zero, but small accumulated output counts
  were present during the audit.

## P3 — cleanup and deferred work

- [ ] Investigate the failed `dev-mqueue.mount`, `run-lock.mount`, and
  `tmp.mount` units reported in several LXCs. Applications were healthy, so
  first determine whether these are harmless container mount artifacts.
- [ ] Configure a UPS and tested automatic shutdown path, or document that no
  UPS protection exists.
- [ ] Finish the OPNsense proxied refresh/deep-link test and the EAP650
  post-login blank-UI investigation.
- [ ] Repair the optical SATA path before starting CT 108 again. Keep
  `dvdstream` stopped and do not attach the media disk to it.
- [ ] Decide whether password authentication should remain enabled for
  non-root accounts on Debian service containers.
- [ ] Plan a management VLAN only after the current HOME management flows are
  fully inventoried.

## Completion checklist

For each completed item:

- [ ] Capture the before state and a rollback path.
- [ ] Apply only the scoped change during an appropriate maintenance window.
- [ ] Verify service health, network behavior, and persistence after restart or
  reboot when relevant.
- [ ] Update all affected `data/*.yaml` records and add sanitized dated
  evidence under `snapshots/`.
- [ ] Run `make check`, inspect the diff for secrets, and commit the result.
