#!/bin/bash

function clean_log() {
    log_files=$(find /var/log/ping_check -atime +3)
    for filename in ${log_files};do
        grep " loss" $filename | grep " 0% packet"
        if [ $? != 0 ]; then
            rm -f $filename
        fi
    done
}

if [ ! -d /var/log/ping_check ];then
    mkdir /var/log/ping_check
fi

target=$1
while true;do
    DT=$(date '+%F_%R')
    ping -c 3600 ${target} | awk '{ print strftime("%Y-%m-%d %H:%M:%S",systime())"\t" $0; fflush() }' >> /var/log/ping_check/ping_${target}_${DT}.log
    clean_log
done
