#!/bin/bash

HOST_NAME=`hostname`
IP=`ifconfig bond0|grep "inet addr"|awk '{print $2}'|awk -F":" '{print $2}'`
if [ -f /etc/rc.local.tail ]
then
#  echo "# netconsole to record panic" >> /etc/rc.local.tail
#  echo "modprobe netconsole netconsole=@$IP/bond0,6666@10.130.254.11/00:11:0a:68:e4:bc" >> /etc/rc.local.tail
  sed -i "/iptables/a\# netconsole to record panic\nmodprobe netconsole netconsole=@$IP/bond0,6666@10.130.254.11/00:11:0a:68:e4:bc" /etc/rc.local.tail
  if [ $? == 0 ];then
    echo "$HOST_NAME is ok"
  fi
  modprobe netconsole netconsole=@$IP/bond0,6666@10.130.254.11/00:11:0a:68:e4:bc
  if [ $? == 0 ];then
    echo "$HOST_NAME netconsole mod done"
  fi
fi
