#!/usr/bin/env bash
#######################################################################
#Author: kellanfan
#Created Time : Thu 25 Oct 2018 09:21:50 AM CST
#File Name: clean-docker.sh
#Description:
#######################################################################

function SafeExec() {
    local cmd=$1
    echo -n "Execing the step [${cmd}]..."
    ${cmd} > /dev/null 2>&1
    if [ $? -eq 0 ];then
        echo -n "OK." && echo ""
    else
        echo -n "Error!" && echo ""
        exit 1
    fi
}
function clean_container() {
    # 清除容器
    cn_list=$(docker ps -a| grep -Ev 'CONTAINER|Up'|awk '{print $1}')
    for i in $cn_list;do
        docker rm $i
    done
}
function clean_image() {
    # 清除dangling image
    dl_image=$(docker images -q -f dangling=true)
    for j in $dl_image;do
        docker rmi $j
    done
}
function clean_volume() {
    # 清除虚悬volume
    dl_volume=$(docker volume ls -qf dangling=true)
    for g in $dl_volume;do
        docker volume rm $g
    done
}
function main() {
    SafeExec clean_container
    SafeExec clean_image
    SafeExec clean_volume
    echo "Done."
}

main