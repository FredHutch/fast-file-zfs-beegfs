#!/bin/bash

node_list=""
textfile_dir="/var/lib/node_exporter/textfile_collector"
interval=10
count=6
timeout=60
cluster=""

metric_help="# HELP node_ping Average ping time to dest over 1 min"
metric_type="# TYPE node_ping gauge"

function ping_node {
  node="${1}"
  fn="${textfile_dir}/ping_${node}"
  echo "${metric_help}" > ${fn}.tmp
  echo "${metric_type}" >> ${fn}.tmp
  ping \
    -i ${interval} \
    -c ${count} \
    -q \
    -w ${timeout} \
    ${node} \
  | awk -F/ -v bc="${cluster}" \
    -v nn=${node} \
    '/^rtt/ {print "node_ping{beegfs_cluster=\""bc"\",dest=\""nn"\"} "$5}' \
  >> ${fn}.tmp \
  && mv ${fn}.tmp ${fn}.prom
}

for node in ${node_list}
do
  ping_node ${node} &
done
