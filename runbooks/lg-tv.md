# Rooted LG TV

The rooted LG C3 is on IOT at `10.0.20.134`, reserved to MAC
`84:90:0A:95:4B:A2`. Its web interface listens on HTTP 8080 and is exposed
internally as `https://tv.home.rvsteele.com` through Caddy.

## Request path

```text
client -> tv.home.rvsteele.com -> 10.0.10.3:443 (Caddy)
       -> 10.0.20.134:8080 (TV)
```

Unbound and AdGuard both return `10.0.10.3` for the web name. No public DNS A
record or WAN port forward is required. OPNsense permits only the scoped
`10.0.10.3 -> 10.0.20.134` TCP 8080 proxy flow for Caddy. The reserved MacBook
has a separate private-network administration exception that covers SSH and
direct troubleshooting; ordinary HOME clients do not have direct IOT access.

## Verification

```sh
dig +short @10.0.10.1 tv.home.rvsteele.com A
dig +short @10.0.10.4 tv.home.rvsteele.com A
curl -I https://tv.home.rvsteele.com/
ssh caddy 'curl -I http://10.0.20.134:8080/'
```

Both resolvers should return `10.0.10.3`; HTTPS and the direct backend should
return a real HTTP response.

## SSH

The MacBook SSH config maps `tv` and `tv.home.rvsteele.com` directly to
`root@10.0.20.134:22`, bypassing the Caddy DNS address. The TV runs Dropbear
2022.83 and advertises public-key and password authentication. The homelab
Ed25519 key was rejected on 2026-11-02, so passwordless SSH is not yet ready.

Install only the public key from `~/.ssh/homelab_ed25519.pub` into the TV's
root authorized-keys file after confirming its correct persistent path for
this webOS build. Never copy the private key to the TV. Keep an existing root
session open while testing a second `ssh tv` session.

TCP 23 Telnet is also listening. It is unencrypted and should be disabled once
SSH key access and a recovery path are verified. Never expose ports 22, 23,
8080, or the Caddy hostname to WAN.
