#!/bin/bash
##############################################################
#Author: Kellan Fan
#Created Time : Sat 12 Jun 2021 10:12:12 AM CST
#File Name: add_zero.sh
#Description:
##############################################################

function get_kg_part() {
    ip=$1
    for part in $(echo ${ip} | awk -F'.' '{print $1,$2,$3,$4}');do
            printf "%03d" ${part}
    done
}
a=$(get_kg_part 192.23.4.13)
echo $a
