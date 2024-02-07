#!/bin/bash
# Author: neilsun@yunify.com
LOG_DIR=$(date '+%Y%m%d_%H%M%S')
LOG_PIDS=()
mkdir ${LOG_DIR}
 
# $2 cmd should log timestamp by itself
function do_log()
{
  $2 > ${LOG_DIR}/$1.log &
  LOG_PIDS=(${LOG_PIDS[*]} $!)
}
function do_loop_log()
{
  interval=$3
  interval=${interval:-1}
  watch -n $interval "date >> ${LOG_DIR}/$1.log ; $2 >> ${LOG_DIR}/$1.log" > /dev/null &
  LOG_PIDS=(${LOG_PIDS[*]} $!)
}
 
do_log mpstat "mpstat -P ALL 1"
do_log pidstat "pidstat 1"
do_log vmstat "vmstat -t 1"
#do_loop_log vmstat "vmstat"
do_loop_log free "free -w" 3
do_loop_log buddyinfo "cat /proc/buddyinfo" 1
do_loop_log netstat "netstat -s"
do_loop_log interrupts "cat /proc/interrupts"
do_loop_log top "top -b -n 1 | head -30"
do_loop_log kswapd "top -b -n 1 | grep kswapd"
 
trap 'for pid in ${LOG_PIDS[@]}; do kill ${pid}; done ' SIGINT SIGTERM
 
for pid in ${LOG_PIDS[@]}; do
  wait ${pid}
done
reset
