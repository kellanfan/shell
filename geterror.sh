#!/bin/bash

###################################################
# ShellName:geterror.sh
# Version: 0.1
# Function: Sorting error logs
# Author: Kellan Fan
# Organization: Qingcloud
# Date: 2016.12.05
# Description: none
####################################################

SHELL_NAME=`basename $0`
SHELL_DIR="/usr/local/sbin"
SHELL_LOG="/var/log/${SHELL_NAME}.log"
LOCK_FILE="/tmp/${SHELL_NAME}.lock"

shell_log() {
     LOG_INFO=$1
     echo "$(date +%F) $(date +%R:%S) : ${SHELL_NAME} : ${LOG_INFO}" >> ${SHELL_LOG}
}
usage() {
    echo "Usage: ${SHELL_NAME}  "
}

shell_lock() {
     touch ${LOCK_FILE}
}
shell_unlock() {
     rm -f ${LOCK_FILE}
}

del_timeoutfile() {
	find /root/ -name "result*" -mtime +1 -print | xargs rm -rf
	find /notifier -mtime +1 -type f |xargs rm -rf
	if [ $? == 0 ];then
		shell_log "clean up done"
	else
		shell_log "clean fail"
	fi
}

sort_log() {
	DATE=`date +%F`
	FILES=`find /notifier -type f -mtime -1`
	HOST_NAME=''
	KEY=''
	for file in $FILES
	do
		HOST_NAME=`basename $file | awk -F"_" '{print $3}'`
		KEY=`awk '/\<h3\>/{print $2}' $file|awk -F"[" '{print $1}'`
		for key in $KEY
		do
			if [[ $key = kern.log ]];then
				awk '/\<p\>/{for(i=7;i<=NF;i++) printf $i" ";printf "\n"}' $file |sort|uniq >> /root/result-$HOST_NAME-$DATE
			elif [[ $key =~ wf ]];then
				awk '/\<p\>/{for(i=7;i<=NF;i++) printf $i" ";printf "\n"}' $file |sort|uniq >> /root/result-$HOST_NAME-$DATE
			elif [[ $key = supervisord.log ]];then
				awk '/\<p\>/{for(i=3;i<=NF;i++) printf $i" ";printf "\n"}' $file |sort|uniq >> /root/result-$HOST_NAME-$DATE
			else
				awk '/\<p\>/{print $0}' $file|sort| uniq >> /root/result-$HOST_NAME-$DATE
			fi
		done		
	done
	if [ -f /root/result-$HOST_NAME-$DATE ];then
		cat /root/result-$HOST_NAME-$DATE | sort |uniq >> /root/result-$DATE
	fi
}
#Subsequent finishing
shell_lock
del_timeoutfile
sort_log
shell_unlock
