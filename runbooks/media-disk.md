# Media disk health and replacement

The WDC WD10JPLX media disk (`/dev/sda`, `/dev/sda1`, UUID
`09678cd4-b5f7-4711-9283-e092bea2b46f`) reported 3,304 pending sectors on
2026-11-01. SMART's headline status still said PASSED; the pending-sector count
is the actionable signal.

## Immediate priorities

1. Avoid unnecessary writes, migrations, scrubs, destructive tests, and repair
   attempts until irreplaceable data is copied elsewhere.
2. Inventory what cannot be recreated. Torrent-seeded media may be replaceable;
   personal data, configurations, and unique metadata may not be.
3. Copy important data to known-good storage and verify the copies.
4. Plan replacement of the disk rather than trusting it after a transient clean
   test.

The repository does not currently identify a backup destination, so no copy or
replacement commands are prescribed here.

## Read-only checks

```sh
smartctl -H -A /dev/sda
smartctl -x /dev/sda
lsblk -f /dev/sda
findmnt /mnt/media
```

Important attributes:

- `Current_Pending_Sector`: 3304
- `Reallocated_Sector_Ct`: 0
- `Offline_Uncorrectable`: 0
- `UDMA_CRC_Error_Count`: 0
- Power-on hours: 35750

Do not start a long SMART test merely to make the number change before data is
safe. A read test can force marginal sectors to surface and may increase stress
on a failing disk.

## Replacement acceptance

After data is protected and a replacement is installed, document its model,
serial-independent identifier, filesystem UUID, mount configuration, SMART
baseline, permissions, and restored hardlink behavior. Update `data/storage.yaml`
and attach a dated Proxmox snapshot.

