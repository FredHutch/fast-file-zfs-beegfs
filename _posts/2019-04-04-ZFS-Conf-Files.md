---
title: ZFS Conf Files
---

For the test host, /etc/zfs/vdev_id.conf is:
```
multipath no
topology sas_direct
phys_per_port 24

#       PCI_ID  HBA PORT CHANNEL NAME
channel 86:00.0 0        e0s
```

Parameters in /etc/zfs/zed.d/zed.rc we will want to change (all commented out in vanilla install):
- `ZED_EMAIL_ADDR` is the address for ZED notification emails space delimited list - default: "root"
- `ZED_EMAIL_PROG` email program to run - default: "mail"
- `ZED_EMAIL_OPTS` command line options for email - default: "-s '@SUBJECT@' @ADDRESS@"
- `ZED_NOTIFY_INTERVAL_SECS` seconds between similar notifications - default: 3600
- `ZED_SCRUB_AFTER_RESILVER` run a scrab after resilver - default: 1
- `ZED_SYSLOG_PRIORITY` default: "daemon.notice"
- `ZED_SYSLOG_TAG` default: "zed"
