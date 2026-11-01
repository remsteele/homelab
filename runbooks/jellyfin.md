# Jellyfin operations

Jellyfin is CT 101 at `10.0.40.10:8096`, exposed internally as
`https://jellyfin.home.rvsteele.com` through Caddy.

## Data and access

- Host `/mnt/media` is mounted as `/media`.
- Movies: `/media/movies`
- TV: `/media/tv`
- Jellyfin is intentionally not in the writable `media` group.
- UPnP/automatic port mapping must remain disabled.
- TCP 8096 must not be forwarded from WAN.

## Basic checks

```sh
pct status 101
pct exec 101 -- systemctl status jellyfin --no-pager
pct exec 101 -- ss -ltnp
pct exec 101 -- findmnt /media
pct exec 101 -- test -r /media/movies
pct exec 101 -- test -r /media/tv
```

Then verify the direct backend from a permitted source and the Caddy URL. If an
LG TV on IOT cannot connect, confirm the explicit IOT-to-`10.0.40.10:8096` pass
rule is above the IOT `LOCAL_NETS` block.

## Missing new media

1. Confirm the Arr import exists at the correct library path.
2. Verify a seeding source and library file share device/inode when a hardlink
   is expected.
3. Confirm Jellyfin can read the file and all parent directories.
4. Run the appropriate Jellyfin library scan.
5. Review Jellyfin logs; do not add write permission merely to fix scanning.

