#!/bin/bash

netns_id=$1
eip_addr=$2

function get_kg_part() {
    ip=$1
    for part in $(echo ${ip} | awk -F'.' '{print $1,$2,$3,$4}');do
            printf "%03d" ${part}
    done
}

kg_part=$(get_kg_part ${eip_addr})
kg_dev=kg${kg_part}p
target_ip=$(ip netns exec ${netns_id} iptables -S -t nat | grep ${eip_addr} | grep PREROUTING | awk '{print $NF}')
eip_gw=$(ip netns exec ${netns_id} route -n | grep kg | awk '{print $1}')

echo "Clean iptables rules.."
ip netns exec ${netns_id} iptables -t nat -D PREROUTING -d ${eip_addr}/32 -m set --match-set int_network_${eip_addr} src -j DNAT --to-destination ${target_ip}
ip netns exec ${netns_id} iptables -t nat -D POSTROUTING -s ${target_ip}/32 -m set --match-set int_network_${eip_addr} dst -j SNAT --to-source ${eip_addr}

echo "Add iptables rules.."
ip netns exec ${netns_id} iptables -t nat -A PREROUTING -d ${eip_addr}/32 -m set ! --match-set int_network_${eip_addr} src -j DNAT --to-destination ${target_ip}
ip netns exec ${netns_id} iptables -t nat -A POSTROUTING -s ${target_ip}/32 -m set ! --match-set int_network_${eip_addr} dst -j SNAT --to-source ${eip_addr}

echo "Flush ipset and add router"
ip netns exec ${netns_id} ipset flush int_network_${eip_addr}
ip netns exec ${netns_id} ipset add int_network_${eip_addr} 192.168.0.0/16
ip netns exec ${netns_id} ip route replace default via ${eip_gw} dev ${kg_dev} table eip-${eip_addr}

