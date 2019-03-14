## Config files in /etc/

Here we keep all version of all configuration files from all servers, including zfs, beegfs, sysctl (tuning)

1. check in original config file and commit change.
1. change to desired setting (including all recommended tuning options) in config file and commit again
1. Verify that we can see what was changed in config file from default value.

Note: If there is a file name collision, for example because different server types have different /etc/rc.local files just create multiple files with descriptive names (/etc/rc.local.meta /etc/rc.local.storage etc.)

### Hardware

### ZFS 

### BeeGFS

