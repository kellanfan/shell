#!/bin/bash

SCRIPT=$(readlink -f $0)
CWD=$(dirname ${SCRIPT})

usage() {
    echo "usage:"
    echo "  $0 setup"
}
if [ $# -lt 1 ]; then
    usage
    exit 1
fi

#调用脚本收集没有添加netconsole的hypernode
bash $CWD/_getnodes.sh
#加载hypernode节点
if [ -f $CWD/nodes ];then
    source $CWD/nodes
fi
#配置netconsole
for i in "${!nodes[@]}"
do
	node="${nodes[$i]}"
	scp -p echo.sh $node:/root/ 2>&1
	ssh -o ConnectTimeout=3 -o ConnectionAttempts=1 $node "/root/echo.sh" >> $CWD/echo.log 2>&1
done
