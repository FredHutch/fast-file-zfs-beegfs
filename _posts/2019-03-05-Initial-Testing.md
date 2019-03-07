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

Error during deb package installation: 
dpkg: error processing archive zfs-dkms_0.8.0-0_amd64.deb (--install):
 trying to overwrite '/usr/src/zfs-0.8.0/include/linux/blkdev_compat.h', which is also in package kmod-zfs-devel 0.8.0-0
dpkg-deb: error: paste subprocess was killed by signal (Broken pipe)

No zfsutils-linux package is created, but utilities are in 'bin' in the repo after build.

### Loading kernel modules

/etc/modprobe.d/blacklist-zfs.conf:
```
# don't load zfs and related modules on boot
blacklist zcommon
blacklist znvpair
blacklist icp
blacklist spl
blacklist zavl
blacklist zunicode
blacklist zfs
```

/etc/rc.local:
```
#!/bin/bash
insmod /lib/modules/4.15.0-45-generic/extra/zfs/spl/spl.ko
insmod /lib/modules/4.15.0-45-generic/extra/zfs/icp/icp.ko
insmod /lib/modules/4.15.0-45-generic/extra/zfs/nvpair/znvpair.ko
insmod /lib/modules/4.15.0-45-generic/extra/zfs/zcommon/zcommon.ko
insmod /lib/modules/4.15.0-45-generic/extra/zfs/avl/zavl.ko
insmod /lib/modules/4.15.0-45-generic/extra/zfs/lua/zlua.ko
insmod /lib/modules/4.15.0-45-generic/extra/zfs/unicode/zunicode.ko
insmod /lib/modules/4.15.0-45-generic/extra/zfs/zfs/zfs.ko
```

### Making udev work

`cp zfs/udev/rules.d/*.rules /lib/udev/rules.d/`
`cp zfs/cmd/vdev_id/vdev_id /lib/udev/`

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

The drives are Seagate ST12000NM0027, which are "12TB" 4k sector drives maybe presenting as 512 sector. ZFS correctly auto sets ashift to 12, and we see 10TiB raw from these drives.

PTS:

[11-disk RAIDZ2 97% full](https://openbenchmarking.org/result/1902140-SP-11DISKRAI64)

[9-disk RAIDZ2 empty](https://openbenchmarking.org/result/1902145-SP-9DISKRAID82)

FIO performance:


| Test | 11 drv | 9 drv | 7 drv |
|---|---|---|---|
|Write | 439758 | 391654 | 272728 |
|Read | 619304 | 396074 | 278128 |
|Mix | 221804 | 196202 | 136796 |
|Total | 1280866 | 983930 | 687652 |


### ZED Frustrations

Since we have built zfs out of git, the system is not really installed into our OS. The ZED and zpool -c functions seem to rely on scripts being present in certain directories, which is not the case with our install.

I was able to confirm the enclosure/bay mapping for our test system like this:

| | | | |
|---|---|---|---|
|05|11|17|23|
|04|10|16|22|
|03|09|15|21|
|02|08|14|20|
|01|07|13|19|
|00|06|12|18|

While I cannot seem to get zpool -c to spit out the sysfs path for each vdev like it should, they path is:

/sys/devices/pci0000:85/0000:85:00.0/0000:86:00.0/host6/port-6:0/expander-6:0/port-6:0:25/end_device-6:0:25/target6:0:
24/6:0:24:0/enclosure/6:0:24:0

With Slot00 through Slot23 in that directory. Each Slotnn directory has a fault file that can be read or written to turn the fault light on (1) or off (0).
