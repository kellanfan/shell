#!/bin/bash
######VARCHAR#######
SCRIPT=$(readlink -f $0)
CWD=$(dirname $SCRIPT)
LOG_FILE="${CWD}/log/scp_nodes.log"
NODE_DIR="${CWD}/nodes"
CONF_DIR="${CWD}/conf"
src=$2
dst=$3
#####FUNC#########
usage() {
    echo "Usage: $(basename $0) <node> <src> <dst>"
    echo "   Ex: $(basename $0) node1 /etc/hosts /etc"
}

log() {
    msg=$*
    DATE=`date +'%F %R'`
    echo "$DATE $msg" >> $LOG_FILE
}

confirm()
{
    msg=$1
    # response="y"
    # call with a prompt string or use a default
    while [ 1 -eq 1 ]
    do
        read -r -p "${1:-msg} click 'y' to continue, 'n' to ignore " response
        case $response in
            [yY][eE][sS]|[yY])
                echo 0
                return
                ;;
            [nN][oO]|[nN])
                echo 1
                return
                ;;
        esac
    done
}
#####PREPARE#######
cd $CWD
# make sure log dir exists
[ -d $CWD/log ] || mkdir $CWD/log
# make sure the para is 3
if [ $# -lt 3 ]; then
    echo "Error: invalid parameters"
    usage
    exit 1
fi
# get conf info
if [ -d "${CONF_DIR}" ];then
    user=$(cat $CWD/conf/user)
    port=$(cat $CWD/conf/port)
else
    user=$(whoami)
    port=22
fi
# get nodes info
if [ -d $NODE_DIR ]; then
    if [ -f $NODE_DIR/${1} ];then
        . $NODE_DIR/${1}
    else
        nodes=("${1}")
    fi
else
    echo "Error: $NODE_DIR not exist!!!"
    exit 1
fi
nodes_list=$(IFS=, ; echo ${nodes[*]})
log "Execing scp $src to ${node_}:${dst}.."
var=`confirm "Are you sure scp [${src}] to [${nodes_list}] : [${dst}]?"`
if [ $var -eq 0 ];then 
    for i in "${!nodes[@]}"; do
        node_="${nodes[$i]}"
        echo -en "Execing scp $src to ${node_}:${dst}..\n"
        log "Execing scp $src to ${node_}:${dst}.."
        scp -r -p -o ConnectTimeout=3 -o ConnectionAttempts=1 -P $port $src $user@$node_:$dst 2>&1 | tee -a ${LOG_FILE}
        if [ $? -eq 0 ];then
            echo ""
            log "Execed scp $src to ${node_}:${dst} OK"
        else
            echo ""
            log "Execed scp $src to ${node_}:${dst} Error"
        fi
        echo
    done
fi

echo "Done"
exit 0
