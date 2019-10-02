# ZFS Terms

_vdev_ - physical devices are used in the ZFS system as virtual devices (vdevs)

_zpool_ - vdevs are aggregated into a ZFS pool

_zfs_ - ZFS file system also known as a dataset

_nv_ or _nvpair_ - name value pair system used internally by ZFS for metadata

_cache_ - a vdev assigned as L2ARC for a pool

_L2ARC_ - Level 2 [Adjustable/Adaptive Replacement Cache](https://en.wikipedia.org/wiki/Adaptive_replacement_cache)

_log_ - a vdev assigned as ZIL for a pool

_ZIL_ - the ZFS Intent Log is the consistency write log

_spare_ - a vdev assigned as a hot spare for one or more pools

_ZED_ - the ZFS Event Daemon is an auxiliary daemon that automates ZFS actions like hot spare replacment

_raidz<n>_ - the ZFS RAID level with number indicating parity disk count
