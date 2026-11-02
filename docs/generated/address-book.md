# Address book

Generated from `data/hosts.yaml` by `tools/generate_docs.rb`. Do not edit by hand.

| Host | Type | VMID | Power | Address | VLAN | MAC | State |
|---|---|---:|---|---|---|---|---|
| pve | bare-metal |  | running | 10.0.10.2 | home | — | confirmed |
| router | qemu-vm | 100 | running | 10.0.10.1 | home | — | confirmed |
| ↳ |  |  |  | 10.0.20.1 | iot | — | confirmed |
| ↳ |  |  |  | 10.0.30.1 | guest | — | confirmed |
| ↳ |  |  |  | 10.0.40.1 | servers | — | confirmed |
| ↳ |  |  |  | 10.0.50.1 | dmz | — | confirmed |
| jellyfin | lxc-unprivileged | 101 | running | 10.0.40.10 | servers | bc:24:11:e3:04:90 | confirmed |
| qbittorrent | lxc-unprivileged | 102 | running | 10.0.40.11 | servers | bc:24:11:97:e7:68 | confirmed |
| ↳ |  |  |  | 10.2.0.2 | proton | — | historical |
| ↳ |  |  |  | 2a07:b944::2:2 | proton | — | historical |
| games | qemu-vm | 103 | running | 10.0.50.10 | dmz | bc:24:11:90:be:0b | confirmed |
| caddy | lxc-unprivileged | 104 | running | 10.0.10.3 | home | bc:24:11:a9:2e:07 | confirmed |
| adguard | lxc-unprivileged | 109 | running | 10.0.10.4 | home | bc:24:11:ad:00:09 | confirmed |
| homepage | lxc-unprivileged | 110 | running | 10.0.10.5 | home | bc:24:11:a3:fa:7d | confirmed |
| uptime-kuma | lxc-unprivileged | 111 | running | 10.0.10.6 | home | bc:24:11:9f:a1:9b | confirmed |
| sonarr | lxc-unprivileged | 105 | running | 10.0.40.12 | servers | bc:24:11:ff:94:4c | confirmed |
| radarr | lxc-unprivileged | 106 | running | 10.0.40.13 | servers | bc:24:11:18:4f:26 | confirmed |
| prowlarr | lxc-unprivileged | 107 | running | 10.0.40.14 | servers | bc:24:11:3b:00:b7 | confirmed |
| dvdstream | lxc-privileged | 108 | stopped | 10.0.40.15 | servers | bc:24:11:93:c9:3f | confirmed |
| eap650 | network-appliance |  | — | 10.0.10.111 | home | — | confirmed |
| lg-c3 | network-client |  | — | 10.0.20.134 | iot | 84:90:0a:95:4b:a2 | confirmed |
