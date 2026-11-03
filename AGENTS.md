# Homelab agent guide

This repository is the source of truth for the live homelab. These instructions
apply to the entire repository and to work performed against the systems it
documents.

## Start here

1. Read `README.md` for the trust model and repository workflow.
2. Route the task using the table below; read the named authoritative data file
   and relevant runbook before acting.
3. Treat `data/*.yaml` as desired/current truth and `snapshots/` as dated
   evidence. A snapshot never silently overrides the data model.
4. Do not edit `docs/generated/*` by hand. Run `make docs` or `make check`.

Use only these state labels in `status` fields: `confirmed`, `historical`,
`planned`, `proposed`, and `needs_verification`. Never promote a claim to
`confirmed` without live evidence or an explicit user report.

## Question and change routing

| Task or question | Read first | Operating guide / supporting evidence |
|---|---|---|
| Add a VM, LXC, appliance, or application | `data/hosts.yaml`, `data/services.yaml`, `data/networks.yaml` | `runbooks/service-onboarding.md` |
| IP, MAC, VMID, VLAN, bridge, gateway, or topology | `data/hosts.yaml`, `data/networks.yaml`, `data/physical.yaml` | `docs/topology.md`, `docs/generated/address-book.md` |
| DNS, DHCP, reservations, local names, or resolver behavior | `data/dns_dhcp.yaml` | `runbooks/service-onboarding.md`, `runbooks/adguard-home.md` |
| AdGuard Home | `data/services.yaml`, `data/dns_dhcp.yaml`, `data/plans.yaml` | `runbooks/adguard-home.md` |
| Rooted LG TV, TV web UI, or TV SSH | `data/hosts.yaml`, `data/services.yaml`, `data/dns_dhcp.yaml` | `runbooks/lg-tv.md`, `runbooks/caddy.md` |
| Homepage, Uptime Kuma, dashboards, or monitoring | `data/services.yaml`, `data/hosts.yaml`, `data/connections.yaml` | `runbooks/observability.md` |
| Caddy, HTTPS, certificates, or reverse proxies | `data/services.yaml`, `data/connections.yaml` | `runbooks/caddy.md`, latest sanitized Caddy snapshot |
| Firewall rule, alias, NAT, port forward, exposure, or segmentation | `data/firewall.yaml`, `data/connections.yaml`, `data/networks.yaml` | `docs/topology.md`, `runbooks/opnsense-api.md`, `data/verification.yaml` |
| OPNsense access, API, recovery, or audit | `data/security.yaml`, `data/firewall.yaml`, `data/dns_dhcp.yaml` | `runbooks/opnsense-api.md`, `runbooks/opnsense-recovery.md`, `automation/discovery/README.md` |
| SSH access or hardening | `data/security.yaml`, `data/hosts.yaml` | `runbooks/ssh-access.md` |
| Storage, mounts, permissions, or media paths | `data/storage.yaml`, `data/media_migrations.yaml` | `runbooks/media-disk.md`, `runbooks/media-hardlinks.md` |
| Jellyfin | `data/services.yaml`, `data/storage.yaml` | `runbooks/jellyfin.md` |
| Seerr, media requests, or Jellyfin/Sonarr/Radarr request integration | `data/services.yaml`, `data/connections.yaml`, `data/security.yaml` | `runbooks/seerr.md` |
| qBittorrent or ProtonVPN | `data/services.yaml`, `data/firewall.yaml`, `data/networks.yaml` | `runbooks/qbittorrent-vpn.md` |
| Terraria or public game access | `data/services.yaml`, `data/firewall.yaml`, `data/dns_dhcp.yaml` | `runbooks/terraria.md` |
| DVD streaming or optical hardware | `data/hosts.yaml`, `data/services.yaml`, `data/physical.yaml` | `runbooks/dvdstream.md` |
| Internet outage or WAN recovery | `data/networks.yaml`, `data/services.yaml` | `runbooks/internet-outage.md` |
| Known fault, unresolved claim, future change, or task priority | `TODO.md`, `data/issues.yaml`, `data/verification.yaml`, `data/plans.yaml` | Relevant runbook and latest snapshot |
| Credentials, tokens, keys, or exposure policy | `data/security.yaml` | `snapshots/README.md`; never inspect or commit secret values |

When an answer spans several domains, update every affected source. A new web
service usually touches hosts, services, DNS/DHCP, connections, firewall,
security, a runbook, and a dated snapshot.

## Live access map

- SSH key on the owner's Mac: `~/.ssh/homelab_ed25519`; its private half must
  never leave the Mac or enter this repository.
- Proxmox: `root@10.0.10.2`.
- OPNsense: `remington@10.0.10.1`; public-key only. This account does not have
  non-interactive privileged access. Do not work around sudo or GUI controls.
- Debian service containers: normally `root@<address>` with public-key login.
- OPNsense API access uses the dedicated `homelab-api` account, is restricted
  to the owner's MacBook at `10.0.10.194/32`, and retrieves its key/secret from
  macOS Keychain. Follow `runbooks/opnsense-api.md`; never print credentials,
  invent endpoints, or place an API key in Git.

For discovery, prefer narrow commands and sanitized outputs. Do not collect
whole configuration trees, environment dumps, password databases, browser
sessions, or full OPNsense configuration exports into the repository.

## Change workflow

For a question, review, diagnosis, or audit, remain read-only unless the user
also asks for a change. For an authorized change:

1. Read the routing sources above and inspect live current state.
2. Identify the exact target, dependencies, rule order, rollback, and expected
   verification result.
3. Preserve unrelated user changes and take a recoverable backup when the
   platform supports one.
4. Apply the smallest scoped change. Never edit generated OPNsense files such
   as `/usr/local/etc/dnsmasq.conf` directly; use its GUI/API and reconfigure.
5. Verify the live outcome, including persistence after reload/reboot when
   relevant. A successful HTTP status alone does not prove an application UI.
6. Update authoritative YAML and sanitized evidence. Leave incomplete work as
   `planned` or `needs_verification`.
7. Run `make check` and `git diff --check`, review the diff for secrets, then
   commit with a reason-oriented message when the requested workflow includes
   repository updates.

For OPNsense API calls, GET is the default. POST is allowed only when the user
has requested the corresponding live change. Before a POST, query the current
object and preserve its UUID/order; after it, call the documented apply or
reconfigure endpoint and query again. Do not delete rules, records, aliases, or
keys unless deletion is explicit.

## Safety-critical invariants

- The media HDD has 3,304 pending sectors. Avoid unnecessary writes and treat
  replacement/backup as urgent even though SMART says PASSED.
- qBittorrent must remain fail-closed: its host-specific DNS, Proton endpoint,
  and block rules precede generic SERVERS rules. Never loosen them as a side
  effect of another change; require a deliberate leak test.
- CT 108 (`dvdstream`) is intentionally stopped because the optical path is
  unreliable. Do not start it casually and never attach the media disk to it.
- OPNsense is the routed firewall. The Proxmox firewall is currently disabled;
  guest `firewall=1` flags do not independently enforce a verified policy.
- Same-VLAN traffic is switched locally and does not cross OPNsense.
- Caddy at `10.0.10.3` terminates internal HTTPS. Caddy-facing web names resolve
  to `.3`; backend host/reservation records retain the service's real address.
- AdGuard Home is `10.0.10.4`, but its DHCP/firewall client rollout remains
  staged. Most clients still use OPNsense DNS until that plan is completed.
- Do not point OPNsense Unbound at AdGuard while AdGuard conditionally forwards
  `home.rvsteele.com` and private PTR queries to Unbound; that creates a loop.
- No management UI, AdGuard, media UI, or SSH service is intended for WAN
  exposure. Terraria TCP 7777 is the documented public exception.

## Secret handling

Never commit passwords, private keys, API key/secret pairs, Cloudflare tokens,
WireGuard keys, password hashes, cookies, recovery codes, or unsanitized config
exports. Record only the location, owner, purpose, scope, and rotation status in
`data/security.yaml`. Store Mac-side secrets in Keychain as documented by the
relevant runbook. Do not print secret values in logs or final responses.

