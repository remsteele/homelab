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

## Security model and limitation

Create a dedicated account and a unique key for this application. Never use a
root or administrator API key. OPNsense downloads the secret only once and does
not retain a recoverable copy; losing it requires generating a new key.

The installed ACLs group read and write operations together:

| Privilege ID | Display name | Matching API scope |
|---|---|---|
| `page-services-dnsforwarder` | Services: Dnsmasq DNS/DHCP: Settings | `api/dnsmasq/*` |
| `page-services-dnsresolver-overrides` | Services: Unbound DNS: Edit Host and Domain Override | specific override CRUD endpoints |
| `page-services-unbound` | Services: Unbound | `api/unbound/*`, including reconfigure |
| `page-filter-api` | Firewall: Rules [new] | `api/firewall/filter/*` |

Therefore, granting Dnsmasq or modern firewall access is not technically
read-only. The user can call both GET and POST endpoints within that module.
Operational policy must default to GET, and credentials should be split or
revoked when ongoing write access is not wanted. A custom OPNsense ACL/plugin
would be required for hard read-only separation.

The firewall API manages the modern **Firewall → Rules** implementation. Do
not assume it manages rules created through legacy pages; verify the rule is
visible through `search_rule` before planning an API change.

## Recommended first deployment

Start DNS-only. Add firewall access later as a separate decision.

1. Give the owner's Mac a fixed HOME address or DHCP reservation. Restrict the
   API group to that `/32` under **Source Networks**. The observed address on
   2026-11-01 was `10.0.10.194`, but do not rely on it until reserved.
2. Go to **System → Access → Groups** and create `homelab-api-dns`.
3. Set its source network to the fixed Mac `/32`.
4. Assign only **Services: Dnsmasq DNS/DHCP: Settings** initially.
5. Go to **System → Access → Users** and create `homelab-agent`:
   - no administrator group;
   - no SSH authorized key;
   - login shell `/sbin/nologin`;
   - use **Scrambled Password** so ordinary local-password login is unavailable;
   - membership only in `homelab-api-dns`.
6. Save, edit the user, and create one API key. Download the key/secret file
   once. Do not place it in this repository or a snapshot.

For Unbound override automation, the narrow override privilege covers CRUD but
the UI applies changes through `/api/unbound/service/reconfigure`, which the
installed ACL places under broad **Services: Unbound**. Granting that broad
privilege is a material expansion. Keep Unbound changes manual unless that
tradeoff is accepted.

For firewall automation, prefer a separate `homelab-api-firewall` group/user
with only **Firewall: Rules [new]**. This contains rule creation, modification,
movement, deletion, and apply operations, so do not add it merely for auditing.

## Store credentials on the Mac

Store both values as generic passwords in macOS Keychain. Replace the
placeholders locally; never paste the resulting values into chat or Git.

```sh
security add-generic-password -U \
  -a homelab-agent -s homelab-opnsense-api-key -w 'PASTE_KEY'
security add-generic-password -U \
  -a homelab-agent -s homelab-opnsense-api-secret -w 'PASTE_SECRET'
```

Afterward, move the downloaded credential file to Trash and empty it only after
the Keychain test succeeds. Record the creation date and privilege scope in
`data/security.yaml`, never the values.

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

Do not use `--insecure` for routine access. `router.home.rvsteele.com` has a
valid Caddy certificate, but API traffic through it arrives at OPNsense from
Caddy (`10.0.10.3`), defeating a Mac `/32` source restriction.

## Read-only connection test

This test reads Dnsmasq status and does not change configuration:

```sh
opn_key=$(security find-generic-password -w \
  -a homelab-agent -s homelab-opnsense-api-key)
opn_secret=$(security find-generic-password -w \
  -a homelab-agent -s homelab-opnsense-api-secret)

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

## Change protocol

For an explicitly requested API change:

1. Query current state and identify the target UUID and sequence.
2. Confirm the endpoint and JSON shape against the installed UI's network call
   or official generated API reference. Do not guess fields.
3. Preserve the current values and OPNsense config-history rollback point.
4. POST the smallest add/set/move operation.
5. POST the module's documented reconfigure/apply endpoint.
6. Search/read the object again and test the resulting DNS or traffic path.
7. Update the source of truth, snapshot only sanitized evidence, and commit.

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

