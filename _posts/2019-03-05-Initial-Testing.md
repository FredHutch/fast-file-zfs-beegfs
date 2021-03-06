---
title: Initial Testing
---

## Setup

### OS and ZFS

ZFS install on Ubuntu 18.04 from git master:

The spl repo is missing autogen.sh, I assume because spl is integrated into zfs with 0.8.0. Did not build spl separately.

### OS Packages

Missing pkg requirements:
`uuid-dev, libblkid-dev`

### Python Packages

Missing:
`python3-setuptools` produces warnings, presumably pyzfs incompatibility?
`python3-dev` does not error until well into the deb build process)
`python3-cffi`

### Installing deb pacakge built from cloned zfs repo

Build following the build procedure on the zfs on linux wiki.

Error during deb package installation: 
dpkg: error processing archive zfs-dkms_0.8.0-0_amd64.deb (--install):
 trying to overwrite '/usr/src/zfs-0.8.0/include/linux/blkdev_compat.h', which is also in package kmod-zfs-devel 0.8.0-0
dpkg-deb: error: paste subprocess was killed by signal (Broken pipe)

No zfsutils-linux package is created, but utilities are in 'bin' in the repo after build.

### Loading kernel modules

A script is installed with the _zfs-test_ package: `/usr/share/zfs/zfs.sh`

This script can load and unload kernel modules - use this to load your newly built modules as it re-calls udev and does other housekeeping.

### Making udev work

Ensure the zfs package installed zvol, vdev, and zfs rules files into /lib/udev/rules.d.

Our /etc/zfs/vdev_id.conf file:
```
multipath no
topology sas_direct
phys_per_port 24

#       PCI_ID  HBA PORT CHANNEL NAME
channel 86:00.0 0        e0s
```

This results in /dev/disk/bv-vdev/e0s0 through e0s23. Our test platform has 24 drives - 12 front and 12 rear all on the same port/enclosure.

## Testing

### Resilvers

#### 51% full 11-disk RAIDZ2 array (44TB/89TB available):

Unloaded took 18 hours:
```
Feb  3 2019 20:08:04.880790864 sysevent.fs.zfs.resilver_start
Feb  4 2019 14:46:20.969945674 sysevent.fs.zfs.resilver_finish
```

Loaded (fio config below) took 55 hours:
```
Feb  4 2019 19:53:38.458910596 sysevent.fs.zfs.resilver_start
Feb  7 2019 03:24:03.113510132 sysevent.fs.zfs.resilver_finish
```

Looks like unloaded rebuild is linear to space used. 97% full unloaded rebuild took 37 hours:

```
Feb  9 2019 16:27:26.067637528 sysevent.fs.zfs.resilver_start
Feb 11 2019 05:46:41.114742985 sysevent.fs.zfs.resilver_finish
```

#### 47% full 11-disk RAIDZ3 array (46/85TB available):

Unloaded took 14 hours:
```
Feb 22 2019 18:41:49.225531883 sysevent.fs.zfs.resilver_start
Feb 23 2019 08:45:48.674542218 sysevent.fs.zfs.resilver_finish
```

Fio job file:
```
[global]
name=ffr-io-load
directory=/loc/ffr_io_load
runtime=7d
time_based=1
blocksize=128k
ioengine=libaio
fallocate=native

[downloads]
rw=write
size=1G
numjobs=20

[reads]
rw=read
size=1G
numjobs=20

[random_mix1]
rw=randrw
rwmixread=70
rwmixwrite=30
numjobs=20
size=128k
```

#### 47%/46% full loaded 11-disk RAIDZ2 vs RAIDZ3:

RAIDZ3 took 83 hours:
```
Mar  6 2019 20:03:41.135789535 sysevent.fs.zfs.resilver_start
Mar 10 2019 07:20:13.331109889 sysevent.fs.zfs.resilver_finish
```
RAIDZ2 took 91 hours:
```
Mar  6 2019 20:04:41.812605041 sysevent.fs.zfs.resilver_start
Mar 10 2019 15:08:14.925554048 sysevent.fs.zfs.resilver_finish
```

fio file:
```
[global]
name=ffr-io-load
directory=/loc5/ffr_io_load
blocksize=128k
ioengine=libaio
fallocate=native
write_bw_log
write_lat_log
write_iops_log
write_hist_log
log_avg_msec=1000
time_based=1
runtime=600000

[downloads5]
directory=/loc5/ffr_io_load
rw=write
size=1G
numjobs=4

[downloads6]
directory=/loc6/ffr_io_load
rw=write
size=1G
numjobs=4

[reads5]
directory=/loc5/ffr_io_load
new_group
rw=read
size=1G
numjobs=4

[reads6]
directory=/loc6/ffr_io_load
new_group
rw=read
size=1G
numjobs=4

[random_mix]
directory=/loc5/ffr_io_load
new_group
rw=randrw
rwmixread=70
rwmixwrite=30
numjobs=4
size=1G

[random_mix]
directory=/loc6/ffr_io_load
new_group
rw=randrw
rwmixread=70
rwmixwrite=30
numjobs=4
size=1G
```

### Drives

The drives are Seagate ST12000NM0027, which are "12TB" 4k sector drives maybe presenting as 512 sector. ZFS correctly auto sets ashift to 12, and we see 10TiB raw from these drives.

### PTS Performance

[11-disk RAIDZ2 97% full](https://openbenchmarking.org/result/1902140-SP-11DISKRAI64)

[9-disk RAIDZ2 empty](https://openbenchmarking.org/result/1902145-SP-9DISKRAID82)

### FIO Performance


| Test | 11 drv | 9 drv | 7 drv |
|---|---|---|---|
|Write | 439758 | 391654 | 272728 |
|Read | 619304 | 396074 | 278128 |
|Mix | 221804 | 196202 | 136796 |
|Total | 1280866 | 983930 | 687652 |

### ZFS Native Encryption

#### Setup

11-drive RAIDZ3 compressed and encrypted pool:
```
zpool create -o feature@encryption=enabled -O compression=lz4 -O encryption=on -O keylocation=prompt -O keyformat=passphrase loc-enc raidz3 <vdevs...>
```

#### Notes
During testing I used a prompted passphrase manually entered. On `zpool import` encrypted zfses are not mounted if they do not have a key available. However, `zfs list` will show the zfs along with the mountpoint, but the mountpoint will be missing from the system. There is no clear indication from zfs that the encrypted file system is missing its key. There is a property _keystatus_ of a zfs that can be queried.

It also appears that you cannot pre-load a zfs key, before the zpool is imported. This makes sense. You can specify `-l` to zpool to try to load encrypted file systems, which will prompt for the key (if you set keylocation to prompt) during import.

#### Testing

Testing CPU use and throughput with ZFS native encryption enabled.

```
fio --name=random-write --ioengine=sync --iodepth=16 --rw=randwrite --bs=4k --direct=0 --size=512m --numjobs=20 --end_fsync=1
```

#### CPU Average System Utilization during fio

| Array Configuration | 10 jobs | 20 jobs | 30 jobs |
| 11-drive RAIDZ3 LZ4 | 7% | 3% | 4% |
| 11-drive RAIDZ3 LS4 enc | 16% | 37% | 34% |
| 11-drive RAIDZ2 LZ4 | 8% | 3% | 4% |
| 11-drive RAIDZ2 LZ4 enc | 18% | 49% | 40% |

[Note: Odd that 10-job tests cause more CPU use than more jobs, but it bears out over repeated testing.]

fio test for above:
```
fio --name=random-write --ioengine=sync --iodepth=16 --rw=randwrite --bs=4k --direct=0 --size=512m --numjobs=<num> --end_fsync=1
```

### ZED

I initially had some problems with ZED not processing drive faults and not called the led statechange script. Ensuring I had all OS packages installed from the repo build procedure and putting vdev_id.conf in place and processed seems to have made everything work.

You will likely want to edit `/etc/zfs/zed.d/zed.rc` to suit your needs.

I was able to confirm the enclosure/bay mapping for our test system like this:

|---|---|---|---|
|05|11|17|23|
|04|10|16|22|
|03|09|15|21|
|02|08|14|20|
|01|07|13|19|
|00|06|12|18|

Our test system has:
```
/sys/devices/pci0000:85/0000:85:00.0/0000:86:00.0/host6/port-6:0/expander-6:0/port-6:0:25/end_device-6:0:25/target6:0:
24/6:0:24:0/enclosure/6:0:24:0
```

With Slot00 through Slot23 in that directory. Each Slotnn directory has a fault file that can be read or written to turn the fault light on (1) or off (0).

ZFS can give additional information during a `zpool status` run by specifying the `-c` flag. Alone, this should produce a list of available scripts (from /etc/zfs/zpool.d). Given one of the scripts as an argument, it will run the script which will produce additional columns of output that are incorporated into the zpool status output. For example, `zpool status -c ses <pool>` will show you the enclosure and slot IDs for each vdev, along with LED states:
```
  pool: loc-enc
 state: ONLINE
  scan: resilvered 24K in 0 days 00:00:01 with 0 errors on Mon Apr  1 20:22:55 2019
config:

        NAME        STATE     READ WRITE CKSUM       enc  encdev  slot  fault_led  locate_led
        loc-enc     ONLINE       0     0     0
          raidz3-0  ONLINE       0     0     0
            e0s0    ONLINE       0     0     0  0:0:24:0    sg24     0          0           0
            e0s1    ONLINE       0     0     0  0:0:24:0    sg24     1          0           0
            e0s2    ONLINE       0     0     0  0:0:24:0    sg24     2          0           0
            e0s3    ONLINE       0     0     0  0:0:24:0    sg24     3          0           0
            e0s4    ONLINE       0     0     0  0:0:24:0    sg24     4          0           0
            e0s5    ONLINE       0     0     0  0:0:24:0    sg24     5          0           0
            e0s6    ONLINE       0     0     0  0:0:24:0    sg24     6          0           0
            e0s7    ONLINE       0     0     0  0:0:24:0    sg24     7          0           0
            e0s8    ONLINE       0     0     0  0:0:24:0    sg24     8          0           0
            e0s9    ONLINE       0     0     0  0:0:24:0    sg24     9          0           0
            e0s10   ONLINE       0     0     0  0:0:24:0    sg24    10          0           0

errors: No known data errors
```

### Useful Links

[ZFS Capacity calculator](https://wintelguy.com/zfs-calc.pl) - appears to be accurate for the arrays I have built and compared.

