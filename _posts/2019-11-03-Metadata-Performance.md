# Issue
We recently discovered that using thee rsync tool to copy files into our BeeGFS cluster wasing taking longer than it should. In selecting and validating BeeGFS, we tested metadata performance and were sure it was noticeaby faster than our previous storage platform. However, the rsync times we were seeing were worse than the previous platform.

## Methodology
We tried examining the rsync output to see where time was added. Comparing two rsync results (tareting each of our storage platform and with a common source) was not useful. In both cases, the time rsync reported during list building was incredibly low.
During these tests our Grafana/Prometheus graphs showed a sustained increase in metadata traffic to our BeeGFS cluster for several hours before a drop to normal levels for several hours before the rsync was done. This time period matched the amount of time the rsync process to our other platform took in its entirety.

Based on the data that seemed to show the rsync targeting BeeGFS spent much more time accessing metadata and about the same amount of time actually transfering files, we assume our metadata performance on BeeGFS is the issue.

## Testing Metadata Performance

### Tests

#### fio
Prior to this problem, we did a full range of tests on our BeeGFS cluster. Using fio, we tested different access patterns across different file sizes and concluded our metadata performance was good based on small file size + small writes/reads performance, which was very good.

#### mdtest
We used mdtest (now part of IOR) as well, but were unable to find our results. However, we all remember not being alarmed by the test.

#### dna_scratch.go
We have an internally-developed tool that can create and write to a huge number of file across a directory hierarchy. This was used too test storage platforms, and produced satisfactory reults for BeeGFS.

#### ls
The most basic metaddata access test is a large, recursive, "long" ls operation. This will read blocks (for directory entries) and run a large number of stat calls to read metadata.

#### pwalk
One of our team members developed [pwalk](https://github.com/fizwit/filesystem-reporting-tools). It is a very simple but extremely useful tool that parallelizes walking a file system. It is very fast.

### Test Results

#### ls
Using ls, we determined that BeeGFS was slower than our previous NFS-based platform. An ls inolving millinos of files took about twice as long on the BeeGFS cluster.

#### pwalk
Using pwalk to walk the entire file structure, we found it took about twice as long on BeeGFS.

#### mdtest
```
-- started at 11/01/2019 13:22:48 --

mdtest-1.9.3 was launched with 1 total task(s) on 1 node(s)
Command line used: src/mdtest "-C" "-T" "-r" "-F" "-d" "/mnt/thorium/fast/_ADM/SciComp/user/bmcgough/mdtest" "-i" "3" "-I" "4096" "-z" "3" "-b" "7" "-L" "-u"
Path: /mnt/thorium/fast/_ADM/SciComp/user/bmcgough
FS: 4731.7 TiB   Used FS: 57.0%   Inodes: 0.0 Mi   Used Inodes: -nan%

1 tasks, 1404928 files

SUMMARY rate: (of 3 iterations)
   Operation                      Max            Min           Mean        Std Dev
   ---------                      ---            ---           ----        -------
   File creation     :        439.763        404.632        422.661         14.357
   File stat         :       3232.092       2645.504       2947.822        239.813
   File read         :          0.000          0.000          0.000          0.000
   File removal      :        449.800        414.304        435.508         15.293
   Tree creation     :        465.711        450.048        456.378          6.737
   Tree removal      :         96.927         84.924         91.069          4.904

-- finished at 11/01/2019 19:14:57 --
```
