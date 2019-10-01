# Important ZFS concepts

## Physical Hierarchy

ZFS arranges everything in a hierarchicial structure begining with the creation of a zpool.

- root: zpool, cache, spares, log
  - vvdev (_virtual_ vdev): raidz, mirror, spare, replacing
    - vvdev (_virtual_ vdev): optional
      - vdevs
    
A _virtual_ vdev is used to define containers that exist at different levels. Since you can have a zpool that is a mirror and raid combination, there can be multiple levels of vvdevs. Uses for vvdevs include:

- raidz or mirror representation - a `raidz[n]-<n>` vvdev exists for each raidz<n> or mirror set (note that the current representation of these are inconsistent with `raidz2-0` and `raidz-0` referring to the same container)
- spare use - a `spare-<n>` vvdev is created to represent the container around a spare while in use with the number corresponding to the order rank of the spare within the pool (the spare resilver and replacement drive resilver are contained here)

Spares, cache, and log (ZiL) are assocaited with and at the same level as pools. Spares can be assocaited with one or more pools while cache and log can be assign a single pool only. Spare and cache are always a single vdev, though more than one of each type be added to a pool, while the log can be a single or mirror set.

## Logical Hierarchy

- root: zpool
  - zfs: dataset
  - zvol: ZFS-managed volume
  
# Common Features

| Feature | Implementation |
| --- | --- |
| Deduplication | pool |
| Compression | pool |
| Encryption | dataset |
| Autoreplace | pool |
| Spares | pool(s) |
| Cache | pool(s) |
| ZiL | pool(s) |
