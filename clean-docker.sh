#!/usr/bin/env bash
#######################################################################
#Author: kellanfan
#Created Time : Thu 25 Oct 2018 09:21:50 AM CST
#File Name: clean-docker.sh
#Description:
#######################################################################

cn_list=`docker ps -qa`
for i in $cn_list;do
    docker rm $i
done
