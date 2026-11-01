# Media relocation and hardlink recovery

Use this when a legacy torrent was renamed or moved so qBittorrent no longer
finds its data, or an Arr library copy is no longer hardlinked.

## Preconditions

- Download source and library destination must both be on `/media`.
- qBittorrent category `movies` maps to `/media/downloads/movies`.
- Category `tv` maps to `/media/downloads/tv`.
- Radarr root is `/media/movies`; Sonarr root is `/media/tv`.
- Writable services use group `media` GID 5000 and umask `0002`.

## Recovery sequence

1. Stop Sonarr or Radarr if it may rename/import during repair.
2. In qBittorrent, use **Set Location** for the torrent's category directory.
3. Let qBittorrent relocate the seeding tree.
4. Recreate the library tree with hardlinks where necessary:

```sh
cp -al -- SOURCE_TREE DESTINATION_PARENT
```

5. Verify representative files are the same inode and have link count at least
   two:

```sh
stat -c '%d %i %h %U:%G %a %n' SOURCE_FILE LIBRARY_FILE
```

The device and inode numbers must match. Do not compare only names or sizes.

6. Set the qBittorrent category, force a recheck, and wait for success.
7. Restart Sonarr/Radarr and verify import/rename behavior preserves the links.
8. Check group and modes; never solve the problem with `chmod 777`.

For multi-file torrents with renamed library episodes, map by size and content
carefully, recreate the exact torrent tree as hardlinks, and let qBittorrent
recheck before the Arr service resumes.

