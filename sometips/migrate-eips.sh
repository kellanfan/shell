#!/bin/bash
#set -x
#set -e

SCRIPT=$(readlink -f $0)
CWD=$(dirname $SCRIPT)
LOG_DIR="${CWD}/migeip_log"
TIMEOUT=30

VG_ID= read("The target VG_ID is <'',HA0,HA1...>: ")

function wait_job() {
    job_id=$1
    cd /pitrix/cli
    ./describe-jobs -j ${job_id} |grep successful > /dev/null
    if [ $? -eq 0 ];then
        return 0
    else:
        return 1
}

if [ -f '${CWD}/eip_list' ];then
    eips=`cat ${CWD}/eip_list`
else
    echo "can not find [eip_list] file.."
    exit
fi

if [ ! -d ${LOG_DIR}];then
    mkdir ${LOG_DIR}
fi

cd /pitrix/cli

for eip in $eips;do
    if [ -z "${VG_ID}" ];then
        ./migrate-eips -e ${eip} >> ${CWD}/${LOG_DIR}/eip-${eip}.log
    else
        ./migrate-eips -e ${eip} -v ${VG_ID}>> ${CWD}/${LOG_DIR}/eip-${eip}.log
    
    job_id=`grep job_id ${CWD}/${LOG_DIR}/eip-${eip}.log | awk -F':' '{print $2}'|awk -F'"' '{print $2}'`
    timer=0
    while true;do
        sleep 5
        wait_job ${job_id}
        if [ $? -eq 0 ];then
            break
        else
            timer=$((${timer}+5))
            if [ ${timer} -ge ${TIMEOUT} ];then
                echo "${job_id} is timeout, please check.." | tee >> ${CWD}/${LOG_DIR}/error.log
                break
            fi
            continue
        fi 
    done
done
