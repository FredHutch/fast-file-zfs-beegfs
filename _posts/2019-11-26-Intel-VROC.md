# Intel VROC
We architected our BeeGFS metadata servers to use a pair of Intel Optane NVMe devices as the metadata storage volume. These are intended to be configured as a mirror pair under the Intel VROC technology.

## VROC?
Virtual Raid On CPU - VROC implements traditional RAID levels in the processor at the level of PCIe lanes, rather than block devices. In theory this is about the fastest way to implement block copy and/or parity writes and reads.

There are two main components to configuring VROC.

### BIOS

#### Enable the VMDs
As the VROC technology applies to PCIe lanes, you need to configure the PCIe controller to enable this on specific lanes. Once configured for VROC, those lanes cannot be used to communicate with anything other than NVMe devices.

To enable VROC, you must switch a PStack (PCIe lane bundle) to VMD (Volume Management Device) mode. This is done in BIOS setup (only, AFAICT). In our case this was done through the BIOS Setup Utility menus `Chipset Configuration` -> `NorthBridge` -> `IIO Configuration` -> `Intel® VMD Technology` -> `Intel® VMD for Volume Management Device on CPU`.

Once there you will see configuration for each processor, and each PStack on each processor. At this point it is helpful to have a block diagram of the motherboard. Once you identify the PStack to which your NVMe devices are attached, change the setting to `enable` for the PStack, and for each VMD under that PStack (these will appear once the PStack is enabled).

Careful as enabling VMD on PStacks where you have other devices like NICs or storage controllers will disable those devices.

Restart after saving the BIOS configuration. Re-enter the BIOS Setup Utility after the restart to configure the RAID volumes.

#### Configure the RAID
In theory you do not have to do this step in the BIOS, but you may want to do so. Intel VROC configures the size of RAID arrays at 95% of the smallest component. This is not as easy to do with mdadm, requiring manual calculation, but is also probably not required (you could create a volume at 100% I suspect).

After enabling the VMD on your NVMe PCIe lanes, you should have a new option at the top level of your BIOS Setup Utilty called `Intel® Virtual RAID on CPU`. This option takes you to a relatively self-explanatory page to configure RAID volumes. You can span VMDs, choose RAID level, strip (stripe?) size, and RWH policy.

Apparently there is a mechanism to eliminate the RAID Write Hole (RWH - when a power failure and drive failure happen simultaneously) but I have been unable to find a good explanation of what this actually does. HP allows it only for RAID 5 volumes, but with pure Intel VMD it can be enabled for all RAID volumes.

Save the BIOS configuration and restart.

### Linux
Once the volumes are configured in the BIOS, all that remains is configuration of `mdadm`. VROC/VMD volumes appear as MD sets to mdadm and the associated kernel modules. Different distributions are at different states in terms of VROC support, but I believe any version of `mdadm` after 4.1 should have support.

You should be able to find the volume(s) you defined in BIOS with `mdadm --detail --scan` and write out mdadm.conf accordingly.

Intel VROC volumes are defined inside a metadata container volume of _IMSM_ type (Intel Matrix Storage Manager) which has been around for a long time as part of the Intel Rapid Storage Technology (RST/RSTe), which paired BIOS-defined RAID volumes and `mdadm` prior to the advent of VROC.

## Our Issues
We began the construction of our BeeGFS cluster on Ubuntu 18.04, which is supported by ThinkParQ, who provide commercial support for BeeGFS and do the BeeGFS development. We had a problem running the metadata service on Ubuntu 18.04 due to threading issues in libc. These issues are not present on 16.04 and the hardware enablement kernels (HWE) for Ubuntu 16.04 include the same kernel version as 18.04, so we reinstalled our metadata nodes with Ubuntu 16.04. Unfortunately, the 16.04 `mdadm` package does not appear to include VROC support.

In the end we are not currently using VROC with our NVMe devices; they are in a traditional, pure, `mdadm` mirror set.

I was also unable to find a way of confirming that an `mdadm` set is actually using the VROC technology or not. In theory, once the PStack is configured for VMD, there is no other way to use those NVMe devices.

## References
These are the docs I was able to find:

[Supermicro](https://www.supermicro.com/manuals/other/AOC-VROCxxxMOD.pdf)

[Intel](https://www.intel.com/content/dam/support/us/en/documents/memory-and-storage/ssd-software/Linux_VROC_6-0_User_Guide.pdf)
