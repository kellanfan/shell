#!/bin/bash

DENYIPLIST="/usr/local/sbin/denyiplist"

IPLIST=`grep "Invalid user" /var/log/auth.log |awk '{print $10}'|sort|uniq`

for ip in $IPLIST; do
    grep $ip $DENYIPLIST > /dev/null
    if [ $? -ne 0 ]; then
        iptables -A INPUT -s $ip -p tcp --dport 22 -j DROP
        echo $ip >> $DENYIPLIST
        /usr/bin/logger "${ip} had been denyed by iptables..."
    fi
done
