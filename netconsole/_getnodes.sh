#!/bin/bash
SCRIPT=$(readlink -f $0)
CWD=$(dirname ${SCRIPT})

cd /pitrix/upgrade/
./exec_nodes.sh hyper -f "if ! lsmod|grep netconsole > /dev/null; then hostname ;fi" > $CWD/bb

nodeList=$(grep -v Done $CWD/bb| grep -v lsmod )
if [[ "x$nodeList" != "x" ]];then
    nodes_str="nodes=("
    for node in ${nodeList};do
        nodes_str="${nodes_str} '${node}'"
    done
    nodes_str="${nodes_str} );"
    echo ${nodes_str} > $CWD/nodes
else
    echo "all hypernode had Done..."
fi
