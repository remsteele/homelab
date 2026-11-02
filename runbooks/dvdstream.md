# DVD Watch Now and optical-drive diagnostics

CT 108 is a privileged Debian 13 container dedicated to the physical optical
drive. It intentionally receives only `/dev/sr0` and `/dev/sg1`; do not mount or
touch host disks from this container.

Current state: CT 108 is intentionally stopped because the DVD workflow was not
working reliably. Starting it should be treated as a deliberate diagnostic or
development action, not as recovery of a known-good production service.

## Passthrough contract

`/etc/pve/lxc/108.conf` contains:

```text
lxc.cgroup2.devices.allow: b 11:0 rwm
lxc.cgroup2.devices.allow: c 21:1 rwm
lxc.mount.entry: /dev/sr0 dev/sr0 none bind,optional,create=file
lxc.mount.entry: /dev/sg1 dev/sg1 none bind,optional,create=file
```

The container has `ffmpeg`, `lsdvd`, `libdvdnav4`, `libdvdread8t64`,
`libdvd-pkg`, and `libdvdcss`. The `dvdvideo` demuxer and real decoded frames
have already been demonstrated.

## Disc inspection

```sh
pct exec 108 -- ls -l /dev/sr0 /dev/sg1
pct exec 108 -- lsdvd /dev/sr0
pct exec 108 -- ffmpeg -demuxers
```

Never blindly alter the drive region. An earlier observation reported RPC Phase
I software behavior with no region set and zero changes/resets.

## Physical repair sequence

1. Shut down Proxmox cleanly.
2. Remove power.
3. Reseat the optical drive's slimline-SATA connector and every adapter/cable in
   that path.
4. Inspect for strain, loose fit, or damaged pins.
5. Boot and run the two-minute test below.
6. If new BadCRC/bus errors appear, replace the cable/adapter before changing
   FFmpeg or application code.

## Post-repair load test

Inside CT 108:

```sh
ffmpeg -loglevel warning -stats \
  -f dvdvideo -title 1 -i /dev/sr0 -t 120 \
  -map 0:v:0 -map 0:a:0 -c copy -f mpegts /dev/null
```

Expected result: content time reaches `00:02:00` and settles at or above 1x
after drive/key warmup.

On Proxmox immediately afterward:

```sh
dmesg -T | grep -Ei 'ata4|sr0|BadCRC|bus error|hard resetting' | tail -n 30
```

Success requires no new BadCRC, ATA bus error, or hard-reset event—not merely a
successful FFmpeg exit.

## HLS proof and future service

MPEG-2/AC3 stream-copy to MPEG-TS HLS has produced a playlist and segments
successfully; a later abort was a drive read failure. Once hardware is stable,
test that exact media in the LG C3 browser before choosing transcoding. The
future service should enumerate episode-length titles, start/stop one HLS job
per playback session, clean stale segments, handle disc removal, and expose an
optional eject action. The HTTP port is intentionally unassigned today.

The Proxmox systemd-257/nesting warning is an open verification item. Enable
nesting only if an actual required function demonstrates the need.

