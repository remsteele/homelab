# OPNsense API access

OPNsense 26.7.5 includes a native JSON API at
`/api/<module>/<controller>/<command>`. It authenticates machine clients with
an API key and secret attached to a local OPNsense user. The key is the HTTP
Basic username and the secret is the HTTP Basic password.

Official references:

- [OPNsense API how-to](https://docs.opnsense.org/development/how-tos/api.html)
- [OPNsense API reference](https://docs.opnsense.org/development/api.html)
- [Local users, privileges, and API keys](https://docs.opnsense.org/manual/how-tos/user-local.html)
- [Dnsmasq API endpoints](https://docs.opnsense.org/development/api/core/dnsmasq.html)
- [Firewall API endpoints](https://docs.opnsense.org/development/api/core/firewall.html)

## Deployed access

The dedicated API identity was provisioned and tested on 2026-11-02:

| Setting | Deployed value |
|---|---|
| User | `homelab-api` |
| Group | `homelab-api-access` |
| Privilege | `WebCfg - All pages` |
| Source network | `10.0.10.194/32` |
| Source reservation | `remington-macbook`, MAC `56:FA:43:CE:40:23` |
| Login shell | `/sbin/nologin` |
| Ordinary password | Scrambled; not usable for normal login |
| SSH/OTP | Not configured |
| API credentials | macOS Keychain, account `homelab-api` |

This is full WebCfg API read/write authority, not technically read-only. The
source restriction limits it to the owner's reserved MacBook address, but a
compromise of that Mac or its API key could still change the firewall. API
mutations therefore require an explicit user request and the change protocol
below. Routine discovery is non-mutating even when an endpoint uses POST for a
search grid.

OPNsense downloads an API secret only once and does not retain a recoverable
copy. The downloaded plaintext file was permanently removed after the Keychain
and authenticated TLS tests succeeded. Losing the Keychain values requires
generating a replacement key in OPNsense.

## ACL limitations

The installed ACLs group read and write operations together:

| Privilege ID | Display name | Matching API scope |
|---|---|---|
| `page-services-dnsforwarder` | Services: Dnsmasq DNS/DHCP: Settings | `api/dnsmasq/*` |
| `page-services-dnsresolver-overrides` | Services: Unbound DNS: Edit Host and Domain Override | specific override CRUD endpoints |
| `page-services-unbound` | Services: Unbound | `api/unbound/*`, including reconfigure |
| `page-filter-api` | Firewall: Rules [new] | `api/firewall/filter/*` |

The deployed `WebCfg - All pages` privilege is broader than these module ACLs
and exposes all WebCfg-backed API methods. A custom OPNsense ACL/plugin would be
required for hard read-only separation. Revoke the key or remove the group
membership if ongoing write capability is no longer wanted.

The firewall API manages the modern **Firewall → Rules** implementation. Do
not assume it manages rules created through legacy pages; verify the rule is
visible through `search_rule` before planning an API change.

## Store credentials on the Mac

Store both values as generic passwords in macOS Keychain. Replace the
placeholders locally; never paste the resulting values into chat or Git.

```sh
security add-generic-password -U \
  -a homelab-api -s homelab-opnsense-api-key -w 'PASTE_KEY'
security add-generic-password -U \
  -a homelab-api -s homelab-opnsense-api-secret -w 'PASTE_SECRET'
```

Afterward, remove the downloaded credential file only after the Keychain test
succeeds. Record the creation date and privilege scope in `data/security.yaml`,
never the values. The current credential file has already been removed.

## TLS and endpoint choice

Prefer a direct HOME connection so OPNsense sees the Mac as the source. The
direct web certificate is self-signed for `OPNsense.internal`; DNS currently
returns all firewall interface addresses for that name. Force `10.0.10.1` and
trust a separately verified copy of the certificate rather than using `-k`.

Export the public certificate, compare its SHA-256 fingerprint with the
certificate shown in OPNsense/browser, then keep it outside the repository:

```sh
mkdir -p ~/.config/opnsense
openssl s_client -connect 10.0.10.1:443 -servername OPNsense.internal \
  </dev/null 2>/dev/null |
  openssl x509 -out ~/.config/opnsense/OPNsense.internal.pem
openssl x509 -in ~/.config/opnsense/OPNsense.internal.pem \
  -noout -sha256 -fingerprint -subject -dates
```

The pinned certificate currently has:

```text
subject: CN=OPNsense.internal
SHA-256: 34:AC:46:8B:E1:AA:35:9E:4A:06:6D:C0:52:F6:E9:06:FB:61:21:C4:64:2C:F2:F7:9E:24:A9:6E:A7:3A:76:E9
expires: 2027-11-01
path:    ~/.config/opnsense/OPNsense.internal.pem
```

Do not use `--insecure` for routine access. `router.home.rvsteele.com` has a
valid Caddy certificate, but API traffic through it arrives at OPNsense from
Caddy (`10.0.10.3`), defeating a Mac `/32` source restriction.

## Non-mutating connection test

This test reads Dnsmasq status and does not change configuration:

```sh
opn_key=$(security find-generic-password -w \
  -a homelab-api -s homelab-opnsense-api-key)
opn_secret=$(security find-generic-password -w \
  -a homelab-api -s homelab-opnsense-api-secret)

curl --fail --silent --show-error \
  --resolve OPNsense.internal:443:10.0.10.1 \
  --cacert ~/.config/opnsense/OPNsense.internal.pem \
  --user "$opn_key:$opn_secret" \
  https://OPNsense.internal/api/dnsmasq/service/status

unset opn_key opn_secret
```

Then test host search with a GET or empty-grid POST against
`/api/dnsmasq/settings/search_host`. Never test access by creating a disposable
record on the production firewall.

The 2026-11-02 validation passed TLS verification, reported firmware 26.7.5,
returned 12 Dnsmasq host rows, and returned 93 firewall rule rows. No
configuration mutation was performed.

## Change protocol

For an explicitly requested API change only:

1. Query current state and identify the target UUID and sequence.
2. Confirm the endpoint and JSON shape against the installed UI's network call
   or official generated API reference. Do not guess fields.
3. Show the exact intended change and obtain explicit user authorization.
4. Preserve the current values and identify the OPNsense config-history
   rollback point or console recovery route.
5. POST the smallest add/set/move operation.
6. POST the module's documented reconfigure/apply endpoint.
7. Search/read the object again and test the resulting DNS or traffic path.
8. Update the source of truth, snapshot only sanitized evidence, and commit.

For Dnsmasq host records the relevant endpoints are:

```text
GET/POST /api/dnsmasq/settings/search_host
GET      /api/dnsmasq/settings/get_host/<uuid>
POST     /api/dnsmasq/settings/add_host
POST     /api/dnsmasq/settings/set_host/<uuid>
POST     /api/dnsmasq/settings/del_host/<uuid>
POST     /api/dnsmasq/service/reconfigure
```

For modern firewall rules the core workflow is `search_rule`, `get_rule`, an
explicit `add_rule`/`set_rule`/`move_rule_before`, followed by `apply`. Rule
ordering is safety-critical; never append blindly.

## Rotation and revocation

API keys are listed on the user's **ApiKeys** tab. Remove a key immediately if
its secret may have been exposed. Rotate by creating a new unique key, updating
Keychain, testing GET access, then deleting the old key. Disable the dedicated
user or remove its group membership to suspend all associated keys.

If the MacBook no longer has `10.0.10.194`, restore its Dnsmasq reservation or
update the group's source network from the OPNsense console/Web UI. Do not
broaden the source network merely to make a failed test pass.

