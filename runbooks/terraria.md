# Terraria server

Terraria runs natively on VM 103 (`games`, `10.0.50.10`) and is publicly
reachable only on TCP 7777 through OPNsense.

## Normal operation

```sh
sudo systemctl status terraria
sudo systemctl start terraria
sudo systemctl stop terraria
sudo systemctl restart terraria
sudo journalctl -u terraria -f
sudo ss -ltnp | grep 7777
```

Prefer `systemctl stop` or `restart`. The wrapper catches SIGTERM, writes
`exit` to `/run/terraria/console`, and lets the server save cleanly. This path
was tested successfully.

To issue a one-off console command while running:

```sh
echo save | sudo tee /run/terraria/console
```

## Version and world compatibility

`/opt/terraria/current` must point to `/opt/terraria/bin/1458`. The restored
`The_Backdoor` world has format header/version 318 and crashes retained server
1.4.4.9 with `System.NullReferenceException`. Do not attempt recovery with
`/opt/terraria/bin/1449`; the same world works with 1.4.5.8.

World and local safety copies are listed in `data/services.yaml`. These local
copies do not constitute a verified backup strategy.

## Public path checks

1. Confirm the service listens on TCP 7777.
2. Confirm OPNsense WAN NAT maps TCP 7777 to `10.0.50.10:7777`.
3. Confirm `terraria.rvsteele.com` is a DNS-only Cloudflare A record.
4. Confirm os-ddclient is updating that record to the current WAN IPv4.
5. Confirm TCP 22 is not forwarded.

The server secret exists in `serverconfig.txt`; never copy it into a ticket,
snapshot, shell transcript, or repository.

