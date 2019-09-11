#!/usr/bin/env python3

import subprocess 
import os
import re

""" zfs-status_exporter 
zpool status command is designed for humans to read.  Convert the output of 
zpool status into machine readable data for use by Prometheus.

Output 4 lines of output for each Zpool object; Pool, Raid device, Vdev.
Output labels for "health", "read_errors", "write_errors", "chsum_errors"

Health status gauge values for devices, are array indexes to the complete list
of device states.  gage values ONLINE == 0, etc.. Timeouts and other errors 
will result in a health value of -1.

"""

health_states = ['ONLINE', 'DEGRADED', 'FAULTED', 'OFFLINE', 'REMOVED', 'UNAVAIL']

# Spares have different states than vdevs and pools, put all values in one array to disambigute 
health_states += ['AVAIL', 'INUSE']

nodename = os.uname().nodename

def vdev_details(zpool_name, vdev_name, parent, state, r, w, cksum):
    """ write metrics for a vdev: health and read, write and chsum errors
        allow some missing metrics for cache, spares
        parent will be empty for zpools, caches, and spares
    """
    health_value = health_states.index(state)

    if parent == "":
        metric_prefix = 'zfs_zpool_'
    else:
        metric_prefix = 'zfs_vdev_'

    metric_name = metric_prefix + 'health'
    print('{}{{hostname="{}",zpool="{}",vdev="{}",parent="{}"}} {}'.format(
           metric_name, nodename, zpool_name, vdev_name, parent, health_value))

    if w:
        metric_name = metric_prefix + 'write_errors'
        print('{}{{hostname="{}",zpool="{}",vdev="{}",parent="{}"}} {}'.format(
              metric_name, nodename, zpool_name, vdev_name, parent, w))

    if r:
        metric_name = metric_prefix + 'read_errors'
        print('{}{{hostname="{}",zpool="{}",vdev="{}",parent="{}"}} {}'.format(
              metric_name, nodename, zpool_name, vdev_name, parent, r))

    if cksum:
        metric_name = metric_prefix + 'cksum_errors'
        print('{}{{hostname="{}",zpool="{}",vdev="{}",parent="{}"}} {}'.format(
              metric_name, nodename, zpool_name, vdev_name, parent, cksum))

def parse_zpool_status(output):
    """ parse the output from zpool status
    output from command line tools are line based
    """
    pool_re = re.compile('^\t\w+\s*')
    vdev_re = re.compile('^\t\s\s*\w+.*')
    special_vdev_re = re.compile('spares|cache|log')
    raid_vdev_re = re.compile('mirror|raidz')
    zpool_name = ""
    vdev_name = ""
    header = ""
    for line in output.splitlines():
        if line[:7] == '  pool:':
            header = True
        if line == 'config:':
            header = False
        if header:
            continue
        if vdev_re.match(line):
            if parent == "spares":
                # spare device, no stats
                (vdev_name, state) = line.split()
                vdev_details("", vdev_name, parent, state, "", "", "")
            elif raid_vdev_re.search(line):
                # mirror or raidz vdev
                (vdev_name, state, read, write, cksum) = line.split()
                vdev_details(zpool_name, vdev_name, zpool_name, state,
                             read, write, cksum)
                parent = vdev_name
            else:
                # normal vdev
                (vdev_name, state, read, write, cksum) = line.split()
                vdev_details(zpool_name, vdev_name, parent, state,
                             read, write, cksum)
        elif pool_re.match(line):
            if special_vdev_re.search(line):
                # only set parent - no metrics
                vdev_name = line.strip()
                parent = vdev_name
            else:
                # zpool
                (zpool_name, state, read, write, cksum) = line.split()
                if zpool_name == 'NAME':
                    continue
                health_value = health_states.index(state)
                vdev_details(zpool_name, zpool_name, "", state,
                             read, write, cksum)
                parent = zpool_name
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
