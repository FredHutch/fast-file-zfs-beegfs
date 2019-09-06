#!/usr/bin/env python3

import subprocess 
import os
import re

""" zfs-status_exporter 
zpool status command is designed for humans to read.  Convert the output of 
zpool status into machine readable data for use by Prometheus.

Output 3 lines of output for each Zpool object; Pool, Raid device, Vdev.
Output labels for "health", "read_bytes", "write_bytes" 

Health status gague values for devices, are array indexes to the complete list
of device states.  gage values ONLINE == 0, etc..

"""

gage_values = ['ONLINE', 'DEGRADED', 'FAULTED', 'OFFLINE', 'REMOVED', 'UNAVAIL']

# Spares have different states than vdevs, put all values in one array to disambigute 
gage_values += ['AVAIL', 'INUSE']
nodename = os.uname().nodename

def device_details(zpool_name, vdev_name, vvdev_name, state, r, w, cksum):
    """ write metrics for a storage device; health, bytes/read, bytes/write
    """
    gage_value = gage_values.index(state)

    gage_name = 'zfs_vvdev_health'
    print('{}{{hostname="{}",zpool="{}",vdev="{}",vvdev="{}",state="{}"}}{}'.format(
           gage_name,nodename, zpool_name, vdev_name, vvdev_name, state, gage_value))

    gage_name = 'zfs_vvdev_write_bytes'
    print('{}{{hostname="{}",zpool="{}",vdev="{}",vvdev="{}",state="{}"}}{}{}'.format(
          gage_name,nodename, zpool_name, vdev_name, vvdev_name, state, w))

    gage_name = 'zfs_vvdev_read_bytes'
    print('{}{{hostname="{}",zpool="{}",vdev="{}",vvdev="{}",state="{}"}}{}'.format(
          gage_name,nodename,zpool_name,vdev_name,vvdev_name,state,r))

def vdev_details(zpool_name, vdev_name, state, r, w, cksum):
    """ write metrics for a zpool Virtual device (RAID); health, bytes/read, bytes/write
    """
    gage_value = gage_values.index(state)

    gage_name = 'zfs_vdev_health'
    print('{}{{hostname="{}",zpool="{}",vdev="{}",state="{}"}}{}'.format(
           gage_name,nodename, zpool_name, vdev_name, state, gage_value))

    gage_name = 'zfs_vdev_write_bytes'
    print('{}{{hostname="{}",zpool="{}",vdev="{}",state="{}"}}{}'.format(
          gage_name,nodename, zpool_name, vdev_name, state, w))

    gage_name = 'zfs_vdev_read_bytes'
    print('{}{{hostname="{}",zpool="{}",vdev="{}",state="{}"}}{}'.format(
          gage_name, nodename, zpool_name, vdev_name, state, r))

def parse_zpool_status(output):
    """ parse the output from zpool status
    output from command line tools are line based
    """
    pool_re = re.compile('^\t\w*\s*')
    vdev_re = re.compile('^\t\s\s\w* .*')
    vvdev_re = re.compile('^\t\s\s\s\s\w* .*')
    zpool_name = None
    vdev_name = None
    header = None
    for line in output.splitlines():
        if line[:7] == '  pool:':
            header = True
        if line == 'config:':
            header = False
        if header:
            continue
        if line == '\tcache' or line == '\tspares':
            zpool_name = line.strip()
            # create an artifical state for cache and spares
            print('zfs_zpool_health{{hostname=\"{}",zpool="{}",state="{}"}}'.format(
                  nodename,
                  zpool_name,
                  "ONLINE"))
        elif vvdev_re.match(line):
            # storage device
            (vvdev_name, state, read, write, cksum) = line.split()
            device_details(zpool_name, vdev_name, vvdev_name, state,
                           read, writer, cksum)
        elif vdev_re.match(line): # RAID, Spares, Cache
            if zpool_name == 'spares':
                (vdev_name, state) = line.split()[0:2]
                gage_value = gage_values.index(state) 
                print('zfs_spare_health{{hostname="{}",zpool="{}",vdev="{}",state="{}"}}{}'.format(
                      nodename,
                      zpool_name,
                      vdev_name,
                      state, gage_value))
            else:
                (vdev_name, state, read, write, cksum) = line.split()
                vdev_details(zpool_name, vdev_name, state, read, write, cksum)
        elif pool_re.match(line):
            (zpool_name, zstate, read, write, cksum) = line.split()
            if zpool_name == 'Name':
                continue
            print('zfs_zpool_health{{hostname=\"{}",zpool="{}",state="{}"}}'.format(
                 nodename,
                 zpool_name,
                 zstate))
        else:
            # blank lines and stuff not tracked
            pass


def run_zpool():
    """ just run the zpool status command,
    timeout is in seconds
    """
    proc = subprocess.run(["zpool", "status"],
                          stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE,
                          universal_newlines = True,
                          timeout=5)
    if proc.returncode != 0:
        if len(stderr):
            sys.stderr.write(proc.stderr)
        # write prometious data with -1
    else:
        return proc.stdout

test_data = """
  pool: thorium_pool
 state: ONLINE
status: One or more devices has experienced an unrecoverable error.  An
	attempt was made to correct the error.  Applications are unaffected.
action: Determine if the device needs to be replaced, and clear the errors
	using 'zpool clear' or replace the device with 'zpool replace'.
   see: http://zfsonlinux.org/msg/ZFS-8000-9P
  scan: none requested
config:

	NAME          STATE     READ WRITE CKSUM
	thorium_pool  ONLINE       0     0     0
	  raidz3-0    ONLINE       0     0     0
	    1:0       ONLINE       0     0     0
	    1:1       ONLINE       0     0     0
	    1:2       ONLINE       0     0     0
	    1:3       ONLINE       0     0     0
	    1:4       ONLINE       0     0     0
	    1:5       ONLINE       0     0     0
	    1:6       ONLINE       0     0     0
	    1:7       ONLINE       0     0     0
	    1:8       ONLINE       0    10     0
	    1:9       ONLINE       0     0     0
	    1:10      ONLINE       0     0     0
	  raidz3-1    ONLINE       0     0     0
	    1:11      ONLINE       0     0     0
	    1:12      ONLINE       0     0     0
	    1:13      ONLINE       0     0     0
	    1:14      ONLINE       0     0     0
	    1:15      ONLINE       0     0     0
	    1:16      ONLINE       0     0     0
	    1:17      ONLINE       0     0     0
	    1:18      ONLINE       0     0     0
	    1:19      ONLINE       0     0     0
	    1:20      ONLINE       0     0     0
	    1:21      ONLINE       0     0     0
	  raidz3-2    ONLINE       0     0     0
	    1:22      ONLINE       0     0     0
	    1:23      ONLINE       0     0     0
	    2:0       ONLINE       0     0     0
	    2:1       ONLINE       0     0     0
	    2:2       ONLINE       0     0     0
	    2:3       ONLINE       0     0     0
	    2:4       ONLINE       0     0     0
	    2:5       ONLINE       0     0     0
	    2:6       ONLINE       0     0     0
	    2:7       ONLINE       0     0     0
	    2:8       ONLINE       0     0     0
	cache
	  sdai        ONLINE       0     0     0
	spares
	  sdah        AVAIL

errors: No known data errors
"""

if __name__ == "__main__":
    devmode = False
    if devmode:
        zpool_output = test_data
    else:
        zpool_output =  run_zpool()
    parse_zpool_status(zpool_output)
