#!/bin/bash
#######################################################################
#Author: kellanfan
#Created Time : Wed 06 Sep 2017 05:53:29 PM CST
#File Name: debmaker.sh
#Description:
#######################################################################

SCRIPT=$(readlink -f $0)
CWD=$(dirname ${SCRIPT})

LOGFILE=/var/log/debmaker.log

logger() {
    Msg=$1
    DATE=`date +'%Y-%m-%d %H:%M:%S'`
    echo "$DATE $msg" >> $LOGFILE
}

