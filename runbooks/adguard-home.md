# AdGuard Home

AdGuard Home runs in unprivileged CT 109 at `10.0.10.4`. DNS listens on TCP
and UDP 53. Caddy serves `https://adguard.home.rvsteele.com` and proxies to the
private HTTP UI at `10.0.10.4:80`.

## Resolver design

- Public names use `https://cloudflare-dns.com/dns-query`, bootstrapped by
  `1.1.1.1` and `1.0.0.1`.
- `home.rvsteele.com` queries go to OPNsense Unbound at `10.0.10.1`.
- Private PTR lookups go to `10.0.10.1`.
- The AdGuard rewrite for `adguard.home.rvsteele.com` returns Caddy at
  `10.0.10.3`.
- Do not configure Unbound to forward back to AdGuard while this conditional
  path exists; that would create a resolver loop.

The administrator username is `remington`. Its randomized password is stored
as the macOS Keychain generic password whose service is
`adguard.home.rvsteele.com`; no plaintext value belongs in this repository.

## Current staged state

The resolver and HTTPS UI are operational, but OPNsense DHCP still distributes
the current firewall/resolver addresses. HOME can reach `10.0.10.4`; other
VLANs still allow DNS only to `This Firewall` and then block private networks.
Consequently, this deployment does not yet filter most client traffic.

## OPNsense rollout

1. Add an Unbound host override:
   `adguard.home.rvsteele.com A 10.0.10.3`.
2. On IOT, GUEST, SERVERS, and DMZ, add an IPv4 TCP/UDP pass from the interface
   net to `10.0.10.4` port 53 above the `LOCAL_NETS` block.
3. Change DHCP DNS to only `10.0.10.4`, one VLAN at a time. Renew one test
   client and verify public, local, and blocked queries before proceeding.
4. Leave qBittorrent CT 102 on `10.0.40.1` until its host-specific DNS rule and
   VPN leak test are deliberately updated. Its first three fail-closed rules
   must stay above generic SERVERS rules.
5. Do not advertise `10.0.10.1` as a secondary if strict filtering is the
   goal: clients may use it and bypass AdGuard. A single resolver is a
   deliberate availability tradeoff until a second filtering instance exists.

## Verification

From a client allowed to reach AdGuard:

```sh
dig +short @10.0.10.4 example.com A
dig +short @10.0.10.4 router.home.rvsteele.com A
dig +short @10.0.10.4 doubleclick.net A
dig +short @10.0.10.4 adguard.home.rvsteele.com A
curl -I https://adguard.home.rvsteele.com/
```

Expected results are public A records, `10.0.10.3` for both local names,
`0.0.0.0` for the blocked test, and an HTTPS login redirect with a valid
certificate.

On CT 109:

```sh
systemctl status AdGuardHome --no-pager
ss -lntup | grep -E ':(53|80)\b'
journalctl -u AdGuardHome --since '10 minutes ago' --no-pager
```

## Upgrade and recovery

Before an upgrade, record the current version, back up
`/opt/AdGuardHome/AdGuardHome.yaml` and `/opt/AdGuardHome/data` outside this
repository, verify the official checksum, and keep the previous binary until
post-restart DNS tests pass. The configuration file contains a password hash
and must not enter a snapshot or Git.

If AdGuard is down during the single-resolver stage, temporarily restore DHCP
DNS to the appropriate OPNsense interface address and renew clients. Do not
change Unbound's upstream to AdGuard as a shortcut.
