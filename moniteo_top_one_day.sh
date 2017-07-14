#!/bin/bash
#######################################################################
#Author: kellanfan
#Created Time : Fri 14 Jul 2017 09:20:39 AM CST
#File Name: moniteo_top_one_day.sh
#Description:
#######################################################################

for i in {1..24}; do
    datetime=`date +'%F_%R'`
    top -b -d 2 -n 1800 >> top-${datetime}.log
done
