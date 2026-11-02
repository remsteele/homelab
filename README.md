# Homelab source of truth

This repository is the declarative record of the homelab described in
`context.txt`. It records what is known now, what is historical, what is
planned, and what still needs to be checked without treating guesses as facts.

## Trust model

Every material record has one of these states:

| State | Meaning |
|---|---|
| `confirmed` | Reported as current and supported by the accumulated context. |
| `historical` | True previously, but not a claim about current state. |
| `planned` | Intended future state; not deployed. |
| `proposed` | A possible change that has not been accepted or applied. |
| `needs_verification` | Plausible or previously attempted, but current state is unknown. |

The files under `data/` are authoritative. Generated tables under
`docs/generated/` are views and must not be edited by hand. Live exports belong
under `snapshots/`; a snapshot is evidence, not automatically desired state.

## Repository map

- `data/hosts.yaml` — Proxmox host, VMs, containers, network appliances, and clients
- `data/networks.yaml` — VLANs, bridges, interfaces, routes, and physical topology
- `data/services.yaml` — ports, URLs, units, config paths, dependencies, and quirks
- `data/firewall.yaml` — ordered interface policy, aliases, NAT, and exposure intent
- `data/dns_dhcp.yaml` — resolver design, DHCP pools/reservations, and DNS records
- `data/storage.yaml` — disks, mounts, paths, permissions, and hardlink design
- `data/media_migrations.yaml` — historical torrent paths, hashes, and hardlink recovery evidence
- `data/connections.yaml` — explicit physical, network, proxy, and application flows
- `data/security.yaml` — security decisions and secret locations (never values)
- `data/issues.yaml` — known problems with symptoms and next checks
- `data/plans.yaml` — desired architecture that is not current
- `data/verification.yaml` — evidence backlog for unknown current state
- `docs/topology.md` — readable topology and policy explanation
- `runbooks/` — recovery and operating procedures
- `runbooks/service-onboarding.md` — checklist for adding a host, DNS, Caddy, and firewall policy
- `runbooks/opnsense-api.md` — least-privilege OPNsense API provisioning and change protocol
- `runbooks/observability.md` — Homepage and Uptime Kuma operation, DNS, backup, and upgrade procedure
- `AGENTS.md` — task router and safety rules for agents working in this repository
- `snapshots/` — dated, sanitized discovery output
- `automation/discovery/` — safe collection guidance
- `tools/validate.rb` — syntax, reference, address, and secret-safety checks
- `tools/generate_docs.rb` — rebuilds derived address and endpoint tables

## Normal workflow

1. Collect a dated, sanitized snapshot.
2. Compare discovery with `data/`.
3. Update current state only when evidence confirms it.
4. Keep desired changes in `data/plans.yaml` until deployed and verified.
5. Run `make check` and review the diff.
6. Commit with the reason for the change.

```sh
make check
make docs
```

## Secret policy

Never commit passwords, token values, private SSH/WireGuard keys, certificate
private keys, cookies, session exports, or recovery codes. It is safe to record
where a secret lives, its purpose, owner, and minimum permission scope. See
`data/security.yaml` and `snapshots/README.md` before adding exports.

`context.txt` is retained as the original imported narrative. New facts should
go into the structured files rather than being appended to that source dump.

## Current high-priority gaps

The urgent finding is the media HDD's 3,304 pending sectors. Back up
irreplaceable data and plan replacement before treating that disk as reliable.
AdGuard Home is deployed and verified, but its network-wide DHCP/firewall
cutover is intentionally still staged; follow `runbooks/adguard-home.md`.
The remaining highest-value checks are the exact OPNsense firewall/NAT order,
the qBittorrent WireGuard leak test and boot race, a real backup/restore plan,
SSH hardening on Proxmox, and the optical-drive SATA repair. The full actionable
list is in `data/verification.yaml` and `data/issues.yaml`.

