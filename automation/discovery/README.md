# Discovery guidance

Discovery is intentionally read-only. Collect narrow evidence, inspect it for
secrets, then place it in a dated snapshot directory. Do not automate writes to
OPNsense, Proxmox, or service hosts from this directory until an explicit,
approval-gated management design exists.

## Proxmox collection checklist

```sh
pveversion -v
ip -br link
ip -br address
ip route
bridge vlan show
cat /etc/network/interfaces
qm list
pct list
qm config 100
pct config 101
pct config 102
pct config 104
pct config 105
pct config 106
pct config 107
pct config 108
findmnt
lsblk -f
```

Review command output before saving. Container config may include mount paths
and network details (expected), and future configs could include sensitive
hook-script arguments (not safe without review).

## Service checks

On each host, favor `systemctl status`, `ss -lntup`, `ip -br address`,
`ip route`, `findmnt`, and exact non-secret configuration fragments. Avoid
`env`, process command lines containing credentials, unfiltered journals, and
whole-directory archives.

## Promotion workflow

1. Save evidence beneath `snapshots/<system>/<date>/`.
2. Compare it to the corresponding `data/*.yaml` record.
3. Resolve drift as either an intentional source update or a live correction.
4. Record the result and close the matching `data/verification.yaml` item.
5. Run `make check`.

