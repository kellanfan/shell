#!/bin/bash
##############################################################
#Author: Kellan Fan
#Created Time : Sun 07 Feb 2021 01:59:18 PM CST
#File Name: a.sh
#Description:
##############################################################
container_id=`docker ps | grep $1 | grep -v '/pause' | awk '{print $1}'`
if [[ -z "$container_id" ]]; then
    echo "ERROR: container id for pod $1 not found"
    exit 1
fi
pid=`docker inspect $container_id | grep -w 'Pid' | grep -wo '[0-9]*'`
nsenter -t $pid -n