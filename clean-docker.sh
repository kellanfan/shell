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

#清除dangling image
dl_image=`docker images -q -f dangling=true`
for j in $dl_image;do
    docker rmi $j
done
