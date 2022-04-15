#!/bin/bash

function killdump() {
    DUMPPID=`ps -ef|grep tcpdump |grep pcap | awk '{print $2}'`
    kill -9 ${DUMPPID}
}

function catch() {
    STIME=`date +%F"@"%H%M%S`
    tcpdump -i tkhjxiu8 icmp and host 172.16.19.12 -tt -nel -w /root/tcpdump/tcpdump-${STIME}.pcap &
}

for i in {1..24};do
    catch
    sleep 3600
    killdump
done
