#!/bin/bash
#######################################################################
#Author: kellanfan
#Created Time : Mon 26 Jun 2017 02:33:52 PM CST
#File Name: scpkey.sh
#Description:
#######################################################################

HOST="192.168.1.1"
USER=ubuntu
PASS=123456
PORT=22


checkalived() {
    ping -c 1 -w 1 $HOST > /dev/null
    if [ $? -eq 0 ];then
        echo "${HOST} is lived"
    else
        echo "${HOST} is not alived"
        exit 1
    fi
}

checkalived

/usr/bin/expect << EOF
set timeout 60
spawn scp -r /root/.ssh ${USER}@${HOST}:~ 
expect "*password*"
send "${PASS}\r"
expect eof
exit
EOF

/usr/bin/expect << EOF
set timeout 60
spawn ssh -p ${PORT} -t ${USER}@${HOST} "sudo cp -r /home/${USER}/.ssh/ /root/"
expect "*password*"
send "${PASS}\r"
expect eof
exit
EOF
