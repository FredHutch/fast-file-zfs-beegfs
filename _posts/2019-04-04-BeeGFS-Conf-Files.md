---
title: BeeGFS Conf Files
---

### Site changes

#### All conf files (mostly)
- `SysMgmtdHost` must be set to a common value for all nodes in a cluster and has no default.
- `connAuthFile` will be set to a shared secret for all nodes in a cluster.
- `connNetFilterFile` will be set to a managed file describing our cluster network to limit access.

#### beegfs-meta.conf
- `storeMetaDirectory` must be set and has no default.

#### beegfs-mgmtd.conf
- `storeMgmtdDirectory` must be set and has no default.

#### beegfs-storage.conf
- `storeStorageDirectory` must be set and has no default.

### Other changes

#### beegfs-meta
- v6 vs. v7 added:
    ```
    logType = logfile
    ```
- We made no changes from v6.
- `storeAllowFirstRunInit` must be set to `false` after server initialization to protect against underlying unmounted volumes.- 
- `tuneUsePerUserMsgQueues` set to `true` to preserve fairness in multi-user environments.

#### beegfs-mgmtd
- v6 vs. v7 has no changes.
- We changed `logLevel` from 2 to 3.
- `sysAllowNewServers` must be set to `false` after cluster initialization.
- `sysAllowNewTargets` must be set to `false` after cluster initialization.
- `storeAllowFirstRunInit` must be set to `false` after server initialization to protect against underlying unmounted volumes.
- `tuneClientAutoRemoveMins` time until unreachable client is removed from cluster - default 30.
- `tuneNumWorkers` threads - recommended cores X 2 - default 4.
- `tune{Meta,Storage}...` - multiple parameters used to tune Low/Emergency pool limits and thresholds.

#### beegfs-client
- v6 vs. v7 has no changes.
- We made no changes.
- `connCommRetrySecs` can be set to 0 to act like NFS hard mount.
- `sysXAttrsEnabled` enable extended attributes.
- `sysACLsEnabled` enable ACLs with extended attributes - decreases performance.
- `tuneUseGlobal{Append,File}Locks` - enable global locking.

#### beegfs-helperd
- v6 vs. v7 has no changes.
- We made no changes.

#### beegfs-storage
- v6 vs. v7 has no changes.
- We made no changes.
- `storeAllowFirstRunInit` must be set to `false` after server initialization to protect against underlying unmounted volumes.
- `tuneUsePerUserMsgQueues` set to `true` to preserve fairness in multi-user environments.
- `tuneNumWorkers` threads processing client requests - should match underlying storage - default 12.
- `tuneNumResyncGatherSlaves` threads per target used to crawl for buddy mirror.
- `tuneNumResyncSlaves` thread per target used to perform resync for buddy mirror.
- `tuneBindToNumaZone` use if storage and network are in the same NUMA zone (check /sys/bus/pci/devices/<device>/numa_node)
