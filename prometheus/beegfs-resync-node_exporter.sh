#!/bin/bash

# $0 <nodetype> <mirrorgroupid> <cluster> <textfile_dir>

nodetype="${1}"
mirrorid="${2}"
cluster="${3}"
textfile_dir="${4}"

output="${textfile_dir}/beegfs_resync"

# _get_resync_metrics
function _get_resync_metrics
{
  beegfs_ctl="/opt/beegfs/sbin/beegfs-ctl"
  beegfs_cmd="--resyncstats"
  ${beegfs_ctl} ${beegfs_cmd} --nodetype=${nodetype} --mirrorgroupid=${mirrorid}
}

# _print_stat <kind> <name> <value> [description]
function _print_metric
{
  metric_prefix="beegfs_resync"
  metric_desc_prefix="beegfs resync stats"
  metric_type="${1}"
  metric_name="${2}"
  metric_value="${3}"
  metric_desc="${4:-${metric_desc_prefix}}"
  echo "# HELP ${metric_prefix}_${metric_name} ${metric_desc}
# TYPE ${metric_prefix}_${metric_name} ${metric_type}
${metric_prefix}_${metric_name}{beegfs_cluster=\"${cluster}\",nodetype=\"${nodetype}\",mirrorgroupid=\"${mirrorid}\"} ${metric_value}"

}

# Job state: Running
# Job start time: Tue Aug 13 15:04:25 2019
# # of discovered dirs: 4332441
# # of discovery errors: 0
# # of synced dirs: 4282485
# # of synced files: 149721396
# # of dir sync errors: 0
# # of file sync errors: 0
# # of client sessions to sync: 0
# # of synced client sessions: 0
# session sync error: No
# # of modification objects synced: 0
# # of modification sync errors: 0

# the variable stats should contain the output of the beegfs-ctl cmd
function extract_metrics
{
  echo "" > "${output}.tmp"
  while read m
  do
    print_metric=0
    if [[ "${m}" =~ 'Job state:' ]]
    then
      kind="gauge"
      label="state"
      val=$(echo "${m}" | grep -c "Job state: Running")
      desc="current resync job state"
      print_metric=1
    elif [[ "${m}" =~ "# of" ]]
    then
      kind="gauge"
      label=$(echo "${m}" | awk -F: '{print $1}' | cut -d ' ' -f 3- | tr ' ' '_')
      val=$(echo "${m}" | awk -F: '{print $2}')
      desc=$(echo "${m}" | awk -F: '{print $1}' | tr '#' 'number')
      print_metric=1
    elif [[ "${m}" =~ "session sync error" ]]
    then
      kind="gauge"
      label="session_sync_error"
      val=$(echo "${m}" | grep -c "session sync error: Yes")
      desc="session sync error"
      print_metric=1
    fi

    if [ "${print_metric}" = "1" ]
    then
      _print_metric "${kind}" "${label}" "${val}" "${desc}" >> "${output}.tmp"
    fi
  done <<< "${stats}"
  mv "${output}.tmp" "${output}.prom"
}

# check stats
stats=$(_get_resync_metrics)
#if [[ "${stats}" =~ "Job state: Running" ]]
#then
  extract_metrics
#else
  #echo "no resync running"
#fi
