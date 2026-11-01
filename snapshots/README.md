# Discovery snapshots

Snapshots are dated evidence of live state. They do not override declarative
intent until reviewed. Store them under:

- `proxmox/YYYY-MM-DD/`
- `opnsense/YYYY-MM-DD/`
- `services/YYYY-MM-DD/<host>/`

Use plain text or stable machine-readable exports. Add a small `README.md` to a
snapshot directory stating who collected it, from where, and whether any output
was redacted.

## Never capture

- password databases or configuration fields containing credentials
- API/token values
- private SSH, WireGuard, TLS, or OPNsense keys
- cookies, browser storage, session headers, or recovery codes
- full environment dumps
- unreviewed support bundles or complete `/etc` archives

Sanitize before the file enters this directory—not after it is committed. IPs,
MACs, routes, ports, package versions, rule identifiers, and public keys are
appropriate when needed.

## Suggested evidence

Proxmox: `pveversion -v`, `ip -br address`, `ip route`, bridge/VLAN output,
sanitized `/etc/network/interfaces`, `qm config`, `pct config`, `findmnt`,
`lsblk -f`, and SMART summaries.

OPNsense: version, interface assignments, aliases, ordered firewall/NAT rules,
Unbound overrides, Dnsmasq ranges/reservations, ddclient status, and Zenarmor
mode/interfaces. Prefer narrow exports and redact credentials before saving.

Services: package/unit versions, `systemctl status`, listeners, mounts, routes,
and sanitized relevant config. Do not copy whole configuration directories.

