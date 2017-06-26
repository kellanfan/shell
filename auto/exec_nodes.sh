#!/bin/bash

# ./exec_nodes.sh hyper "virsh list  | awk '{print \$2}' | grep 'i-' | xargs -I % virsh shutdown %"

# set -x

SCRIPT=`readlink -f $0`
CWD=`dirname $SCRIPT`
cd $CWD
NODE_DIR="$CWD/node"

LOG_FILE="/pitrix/bin/update.d/update.log"
. /pitrix/inc/common_inc.sh

function logit()
{
   msg=$1
   DATE=`date +'%Y-%m-%d %H:%M:%S'`
   echo "$DATE $msg" >> $LOG_FILE
}

function usage()
{
    echo "Usage: $(basename $0) <nodes_file> [-f] <cmd>"
    echo "       -f means force yes"
    echo "   Ex: $(basename $0) all \"apt-get update\""
    echo "   Ex: $(basename $0) all \"grep pitrix /etc/fstab\""
    echo "   Ex: $(basename $0) all -f \"ls /tmp\""
}

if [ $# -lt 2 ]; then
    echo "Error: invalid parameters"
    usage
    exit 1
fi

if [ -d ${1} ]; then
    _nodes=`ls ${1}`
    nodes=($_nodes)
elif [ ! -f ${NODE_DIR}/${1} ]; then
    nodes=("${1}");
else
    . ${NODE_DIR}/${1}
fi

shift
force_yes="false"
if [[ "x$1" == "x-f" ]]; then
    force_yes="true"
    shift
fi

cmd=$@

nodes_str=$(IFS=, ; echo "${nodes[*]}")

if [ "x$force_yes" = "xfalse" ]; then
    val=`confirm "ARE YOU SURE to run [$cmd] on [$nodes_str]"`
    if [[ ${val} -ne 0 ]]; then
        exit 0
    fi
fi

# echo -e "EXECING [$cmd] ON [$nodes] ... "
logit "Execing [$cmd] on [$nodes] ..."

CONF_FILE="/pitrix/bin/update.d/exec_nodes.conf`date +'%Y%m%d%H%M%S'`_$$"

for i in "${!nodes[@]}"
do
    echo "${nodes[$i]}#$cmd" >> $CONF_FILE
done

cat $CONF_FILE | parallel -j 10 /pitrix/upgrade/exec_one_node.sh {1}

echo "Done."
exit 0


