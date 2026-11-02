# New service onboarding

Use this checklist when adding a VM, LXC, appliance, or application. The goal
is to keep address assignment, DNS, HTTPS, firewall policy, and the source of
truth synchronized.

## 1. Allocate the host

Choose an unused VMID, hostname, VLAN, IP address, and MAC address. Check the
subnet and DHCP pool in `data/networks.yaml` and `data/dns_dhcp.yaml` before
creating anything. Infrastructure with a static address should normally live
outside the dynamic `.100-.199` pools.

Record at least:

- VMID and virtualization type
- hostname and role
- IP/prefix, gateway, VLAN, bridge, and MAC
- CPU, memory, swap, disk, mounts, and boot behavior
- application listeners and whether they are direct or proxied

For a Proxmox guest, the live MAC is visible in `qm config <vmid>` or
`pct config <vmid>` under the network interface's `hwaddr` value.

## 2. Add the Dnsmasq host identity

In OPNsense, open **Services → Dnsmasq DNS & DHCP → Hosts** and create a row:

| Field | Pattern |
|---|---|
| Host | short hostname, such as `example` |
| Domain | `home.rvsteele.com` |
| IP addresses | the guest's backend/service IP |
| Hardware addresses | the guest NIC MAC |
| Description | concise service role |

For a DHCP guest this is the fixed lease. For a statically addressed guest it
is still useful as the authoritative MAC/IP inventory and prevents accidental
reuse, but the guest retains its address without DHCP.

The Dnsmasq host row and a user-facing Caddy name serve different purposes in
this design. Dnsmasq records the actual guest address. A browser hostname for a
proxied service must resolve to Caddy instead:

```text
example host identity -> 10.0.<vlan>.<backend>
example.home.rvsteele.com web name -> 10.0.10.3 (Caddy)
```

Do not point the browser name directly at the backend when Caddy is expected
to terminate HTTPS.

## 3. Add internal DNS

For a Caddy-proxied web service:

1. Add an OPNsense Unbound host override for
   `<name>.home.rvsteele.com A 10.0.10.3` while clients use OPNsense DNS.
2. Add the same name as an AdGuard DNS rewrite to `10.0.10.3` for clients using
   AdGuard.
3. Keep any backend-only record distinct if administrators need direct access.

For a non-web service that clients should reach directly, point its internal
record to the service IP and document the port separately.

Do not create a public Cloudflare record for an internal-only service. Caddy's
DNS-01 certificate flow does not require a public A record or inbound WAN
ports 80/443.

## 4. Add Caddy

Add a block to `/etc/caddy/Caddyfile` using the established Cloudflare DNS-01
pattern and the backend's actual IP and port. Back up the file, validate the
candidate configuration, then reload:

```sh
caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
systemctl reload caddy
systemctl is-active caddy
```

Test with `curl --resolve` before depending on normal DNS:

```sh
curl -I --resolve example.home.rvsteele.com:443:10.0.10.3 \
  https://example.home.rvsteele.com/
```

## 5. Add the minimum firewall policy

Identify the source VLANs, destination IP, protocol, and ports. On restricted
VLANs, an allow rule to another private subnet must appear above the
`LOCAL_NETS` block. Do not add a broad cross-VLAN allow when one destination
and port are sufficient.

Same-VLAN traffic is switched locally and does not traverse OPNsense. The
Proxmox firewall is currently disabled, so a guest's `firewall=1` flag alone
does not enforce same-VLAN isolation.

Never alter qBittorrent's host-specific DNS/VPN rules as part of generic
service onboarding; its fail-closed rules must remain first and require a leak
test after any deliberate change.

## 6. Verify both DNS paths and HTTPS

```sh
dig +short @10.0.10.1 example.home.rvsteele.com A
dig +short @10.0.10.4 example.home.rvsteele.com A
curl -I https://example.home.rvsteele.com/
```

Both resolvers should return `10.0.10.3` for a Caddy-proxied name. Also test
the backend directly from Caddy, authentication, page refresh, deep links, and
WebSockets/API calls where applicable. A successful HEAD request alone does
not prove the application UI works.

## 7. Update and commit the source of truth

Update the relevant records in:

- `data/hosts.yaml`
- `data/services.yaml`
- `data/dns_dhcp.yaml`
- `data/connections.yaml`
- `data/firewall.yaml`
- `data/security.yaml` for secret locations only, never values
- dated sanitized snapshots

Then run:

```sh
make check
git diff --check
```

Commit only after live state, documentation, and generated views agree.
