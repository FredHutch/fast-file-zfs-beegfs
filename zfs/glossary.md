# ZFS Terms

_vdev_ - physical devices are used in the ZFS system as virtual devices (vdevs)

_zpool_ - vdevs are aggregated into a ZFS pool

_zfs_ - ZFS file system also known as a dataset

_nv_ or _nvpair_ - name value pair system used internally by ZFS for metadata

_cache_ - a read-only cache device associated with a zpool also known as L2ARC (Level 2 [Adjustable/Adaptive Replacement Cache](https://en.wikipedia.org/wiki/Adaptive_replacement_cache))

_L2ARC_ - a read-only cache device assocaited with a zpool also known as cache

_log_ - a write-log associated with a zpool also known as ZIL (ZFS Intent Log)

_ZED_ - the ZFS Event Daemon is an auxiliary daemon that automates ZFS actions like hot spare replacment

_raidz<n>_ - the ZFS RAID level with number indicating parity disk count
