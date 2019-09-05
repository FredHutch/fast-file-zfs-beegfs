#!/bin/bash

cluster=""
textfile_dir="/var/lib/node_exporter/textfile_collector"
beegfs_ctl="/opt/beegfs/sbin/beegfs-ctl"

# metrics
#
# for metadata node and storage target (not node)
#
# reachability
metric_reachable="# HELP beegfs_node_reachable reachability of node
# TYPE beegfs_node_reachable gauge
beegfs_node_reachable{beegfs_cluster=\"${cluster}\","
# consistency
metric_consistent="# HELP beegfs_node_consistent consistency of node
# TYPE beegfs_node_consistent gauge
beegfs_node_consistent{beegfs_cluster=\"${cluster}\","
# mgmembertype
metric_mirror_primary="# HELP beegfs_node_mirror_primary is node primary?
# TYPE beegfs_node_mirror_primary gauge
beegfs_node_mirror_primary{beegfs_cluster=\"${cluster}\","
metric_mirror_secondary="# HELP beegfs_node_mirror_secondary is node secondary?
# TYPE beegs_node_mirror_secondary gauge
beegfs_node_mirror_secondary{beegfs_cluster=\"${cluster}\","
# space info (bytes)
metric_space_total_gib="# HELP beegfs_node_space_total_gib total space on target in gib
# TYPE beegfs_node_space_total_gib gauge
beegfs_node_space_total_gib{beegfs_cluster=\"${cluster}\","
metric_space_free_gib="# HELP beegfs_node_space_free_gib free space on target in GiB
# TYPE beegfs_node_space_free_gib gauge
beegfs_node_space_free_gib{beegfs_cluster=\"${cluster}\","
metric_space_free_pct="# HELP beegfs_node_space_free_pct percent of space in GiB free on target
# TYPE beegfs_node_space_free_pct gauge
beegfs_node_space_free_pct{beegfs_cluster=\"${cluster}\","
# space info (inodes)
metric_space_total_inodes="# HELP beegfs_node_space_total_inodes total inodes on target in millions (M)
# TYPE beegfs_node_space_total_inodes gauge
beegfs_node_space_total_inodes{beegfs_cluster=\"${cluster}\","
metric_space_free_inodes="# HELP beegfs_node_space_free_inodes total free inodes on target in millions (M)
# TYPE beegfs_node_space_free_inodes gauge
beegfs_node_space_free_inodes{beegfs_cluster=\"${cluster}\","
metric_space_free_inodes_pct="# HELP beegfs_node_space_free_inodes_pct percentage of inodes free on target
# TYPE beegfs_node_space_free_inodes_pct gauge
beegfs_node_space_free_inodes_pct{beegfs_cluster=\"${cluster}\","
metric_node_count="# HELP beegfs_node_count count of current nodes in cluster
# TYPE beegfs_node_count gauge
beegfs_node_count{beegfs_cluster=\"${cluster}\","

# $ beegfs-ctl --listnodes --nodetype=mgmt --reachable
# <hostname-mgmt> [ID: 1]
#    Reachable: <yes>
function check_mgmt_service
{
  reachability=0
  /usr/sbin/beegfs-ctl --listnodes --nodetype=mgmt --reachable | grep -qc "Reachable: <yes>" && reachability=1
  hostn=$(/usr/sbin/beegfs-ctl --listnodes --nodetype=mgmt | head -1 | awk '{print $1}')
  if [ -n "${hostn}" ]
  then
    echo "${metric_reachable}nodetype=\"mgmt\",hostname=\"${hostn}\"} ${reachability}" > ${textfile_dir}/beegfs_${hostn}.tmp
    mv ${textfile_dir}/beegfs_${hostn}.tmp ${textfile_dir}/beegfs_${hostn}.prom
  else
    echo "$(date): host was empty"
  fi
}

# report_node_counts <nodetype>
function report_node_count
{
  nodetype="${1}"
  beegfs_cmd="--listnodes --nodetype=${nodetype}"
  node_count=$(${beegfs_ctl} ${beegfs_cmd} | wc -l)
  echo "${metric_node_count}nodetype=\"${nodetype}\"} ${node_count}" > ${textfile_dir}/beegfs_${nodetype}_nodes.tmp
  mv ${textfile_dir}/beegfs_${nodetype}_nodes.tmp ${textfile_dir}/beegfs_${nodetype}_nodes.prom
}

function check_mirrored_service
{
  # $ beegfs-ctl --listtargets --nodetype=meta --state --longnodes --spaceinfo --mirrorgroups
  # MirrorGroupID MGMemberType TargetID     Reachability  Consistency        Total         Free    %      ITotal       IFree    %   NodeID
  #============= ============ ========     ============  ===========        =====         ====    =      ======       =====    =   ======
  #            11      primary       21          Offline         Good     662.9GiB     531.7GiB  80%     1327.4M     1064.3M  80%   beegfs-meta <hostname> [ID: 21]
  #            11    secondary       11          Offline         Good     662.9GiB     531.8GiB  80%     1327.4M     1064.3M  80%   beegfs-meta <hostname> [ID: 11]

  node_type="${1}"
 
  out=$(/usr/sbin/beegfs-ctl --listtargets --nodetype=${node_type} --state --longnodes --spaceinfo --mirrorgroups | egrep -v '^MirrorGroupID' | egrep -v '^===')

  cols=$(echo "${out}" | awk '{print NF}' | sort -u)
  if [ "${cols}" != "15" ]
  then
    echo "bad cols: ${out}" >> /root/problems
  fi

  while read l
  do
    host=$(echo "${l}" | awk '{print $13}')
    echo "" > ${textfile_dir}/beegfs_${host}.tmp
    MGID=$(echo "${l}" | awk '{print $1}')
    primary=$(echo "${l}" | awk '{print $2}' | egrep -c "primary")
    echo "${metric_mirror_primary}nodetype=\"${node_type}\",hostname=\"${host}\",mirrorgroupid=\"${MGID}\"} ${primary}" >> ${textfile_dir}/beegfs_${host}.tmp
    secondary=$(echo "${l}" | awk '{print $2}' | egrep -c "secondary")
    echo "${metric_mirror_secondary}nodetype=\"${node_type}\",hostname=\"${host}\",mirrorgroupid=\"${MGID}\"} ${secondary}" >> ${textfile_dir}/beegfs_${host}.tmp
    reachability=$(echo "${l}" | awk '{print $4}' | egrep -c "Online")
    echo "${metric_reachable}nodetype=\"${node_type}\",hostname=\"${host}\",mirrorgroupid=\"${MGID}\"} ${reachability}" >> ${textfile_dir}/beegfs_${host}.tmp
    consistency=$(echo "${l}" | awk '{print $5}' | egrep -c "Good")
    echo "${metric_consistent}nodetype=\"${node_type}\",hostname=\"${host}\",mirrorgroupid=\"${MGID}\"} ${consistency}" >> ${textfile_dir}/beegfs_${host}.tmp
    bytes_total=$(echo "${l}" | awk '{print $6}' | tr -d '[A-Za-z]')
    echo "${metric_space_total_gib}nodetype=\"${node_type}\",hostname=\"${host}\"} ${bytes_total}" >> ${textfile_dir}/beegfs_${host}.tmp
    bytes_free=$(echo "${l}" | awk '{print $7}' | tr -d '[A-Za-z]')
    echo "${metric_space_free_gib}nodetype=\"${node_type}\",hostname=\"${host}\"} ${bytes_free}" >> ${textfile_dir}/beegfs_${host}.tmp
    bytes_pct_free=$(echo "${l}" | awk '{print $8}' | tr -d '%')
    echo "${metric_space_free_pct}nodetype=\"${node_type}\",hostname=\"${host}\"} ${bytes_pct_free}" >> ${textfile_dir}/beegfs_${host}.tmp
    inodes_total=$(echo "${l}" | awk '{print $6}' | tr -d '[A-Za-z]')
    echo "${metric_space_total_inodes}nodetype=\"${node_type}\",hostname=\"${host}\"} ${inodes_total}" >> ${textfile_dir}/beegfs_${host}.tmp
    inodes_free=$(echo "${l}" | awk '{print $7}' | tr -d '[A-Za-z]')
    echo "${metric_space_free_inodes}nodetype=\"${node_type}\",hostname=\"${host}\"} ${inodes_free}" >> ${textfile_dir}/beegfs_${host}.tmp
    inodes_pct_free=$(echo "${l}" | awk '{print $8}' | tr -d '%')
    echo "${metric_space_free_inodes_pct}nodetype=\"${node_type}\",hostname=\"${host}\"} ${inodes_pct_free}" >> ${textfile_dir}/beegfs_${host}.tmp
    mv ${textfile_dir}/beegfs_${host}.tmp ${textfile_dir}/beegfs_${host}.prom
  done <<< "${out}"
}

check_mgmt_service
check_mirrored_service meta
check_mirrored_service storage
report_node_count mgmt
report_node_count meta
report_node_count storage
report_node_count client
