#!/usr/bin/env bash
#######################################################################
#Author: kellanfan
#Created Time : Tue 28 Aug 2018 09:39:17 AM CST
#File Name: initos.sh
#Description: 初始化自己的机器环境
#######################################################################

#######variable#########
SCRIPT=$(readlink -f $0)
CWD=$(dirname $SCRIPT)
DATA_DIR=$CWD/data
CONF_DIR=$CWD/conf
. $CONF_DIR/common.conf
log_file=/var/log/initos.log
########################
function Usage() {
    echo "$0 [common|shadow]"
    echo "  common: 普通模式安装"
    echo "  shadow: 翻墙模式安装"
    echo "Example: $0 common"
    echo "Example: $0 shadow"
}

function check_network() {
    echo "===check_network==="
    ping -c 1 -w 3 www.baidu.com > /dev/null
    if [ $? -ne 0 ];then
        exit 1
    fi
}

function update_ssh() {
    echo "===update ssh config==="
    if [ -d ~/.ssh ];then
        rm -rf ~/.ssh
    fi
    cp -r $DATA_DIR/ssh ~/.ssh
    chmod 600 ~/.ssh/id_rsa
    sed -i "/^Port/s/22/${ssh_port}/" /etc/ssh/sshd_config
    sed -i '/^#PasswordAuthentication/a\PasswordAuthentication no' /etc/ssh/sshd_config
    service ssh reload
}

#update apt
function update_apt() {
    echo "===update apt repo==="
    local os_version=$(cat /etc/issue|awk '{print $2}'|cut -d'.' -f 1)
    cp /etc/apt/sources.list /etc/apt/sources.list-bak
    if [ "$os_version" == '14' ];then
        cp $DATA_DIR/sources.list-14 /etc/apt/sources.list
    elif [ "$os_version" == "16" ];then
        cp $DATA_DIR/sources.list-16 /etc/apt/sources.list
    elif [ "$os_version" == "18" ];then
        cp $DATA_DIR/sources.list-18 /etc/apt/sources.list
    fi
    apt-get clean; apt-get autoclean;
    apt-get update
}

#update env
function update_env() {
    echo "===update env==="
    if [ ! -d /root/.backup ];then
        mkdir /root/.backup
    fi
    cat <<EOF >> ~/.bashrc
PS1="\u@\[\e[1;93m\]\h\[\e[m\]:\w\\$\[\e[m\] "
HISTTIMEFORMAT="%F %T `whoami` "
export PYTHONDONTWRITEBYTECODE=False
export WORKON_HOME=$HOME/.virtualenvs
source /usr/local/bin/virtualenvwrapper.sh
EOF
    cat <<EOF >> /etc/profile
#save history 
IP=$(who -u am i|awk '{print $NF}'|sed -e 's/[()]//g')
HISTDIR=/opt/.history
if [ -z $IP ];then
    IP=$(hostname)
fi
if [ ! -d $HISTDIR ];then
    mkdir -p $HISTDIR
    chmod 777 $HISTDIR
fi
if [ ! -d $HISTDIR/$LOGNAME ];then
    mkdir -p $HISTDIR/$LOGNAME
    chmod 300 $HISTDIR/$LOGNAME
fi
export HISTSIZE=4000
#DateTime=$(date +%F_%T)
DateTime=$(date +%F_%H%M%S)
export HISTFILE="$HISTDIR/$LOGNAME/$IP.histroy.$DateTime"
HISTTIMEFORMAT='%F %T '  
chmod 600 $HISTDIR/$LOGNAME/*.history.* 2>/dev/null
EOF
}

function update_vim() {
    echo "===update vimrc==="
    cp ${DATA_DIR}/vimrc ~/.vimrc
}

function install_package_common() {
    #install package
    echo "===install packages==="    
    apt-get install -y -qq git python3-pip ipython3 redis etcd mongodb postgresql
    curl -sSL https://get.daocloud.io/docker | sh
    pip3 install virtualenv
    pip3 install virtualenvwrapper
}

function install_package_shadow() {
    echo "===install packages==="
    apt-get install -y -qq python3-pip
}

function init_shadownsocks() {
    echo "===install shadowsocks==="
    pip3 install shadowsocks
    if [ $? -ne 0 ];then
        tar zxf ${DATA_DIR}/shadowsocks-2.8.2.tar.gz -C /tmp
        cd /tmp/shadowsocks-2.8.2/
        python3 setup.py install
    fi
	if [ ! -d /etc/shadowsocks ];then
		mkdir /etc/shadowsocks
	fi
    cp ${DATA_DIR}/config.json /etc/shadowsocks/
    /usr/local/bin/ssserver -c /etc/shadowsocks/config.json -k Zhu88jie -d start
    sed -i "/^exit/i\/usr/local/bin/ssserver -c /etc/shadowsocks/config.json -k Zhu88jie -d start" /etc/rc.local
}

function config_service() {
    # etcd
    sed -i '/ETCD_LISTEN_CLIENT_URLS/aETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"' /etc/default/etcd
    sed -i '/ETCD_ADVERTISE_CLIENT_URLS/aETCD_ADVERTISE_CLIENT_URLS="http://0.0.0.0:2379"' /etc/default/etcd
    systemctl restart etcd
    # redis
    sed -i '/^bind/s/^/#/' /etc/redis/redis.conf
    sed -i '/bind 127.0.0.1/abind *' /etc/redis/redis.conf
    systemctl restart redis
    # mongodb
    sed -i 's/bind_ip = 127.0.0.1/bind_ip = 0.0.0.0/' /etc/mongodb.conf
    systemctl restart mongodb
    # postgresql
    sed -i "/listen_addresses/alisten_addresses = \'*\'" /etc/postgresql/10/main/postgresql.conf
    systemctl restart postgresql
}

function log() {
    msg=$*
    DATE=$(date +'%Y-%m-%d %H:%M:%S')
    echo "${DATE} ${msg}" >> ${log_file}
}

function SafeExec() {
    local cmd=$1
    echo -n "Execing the step [${cmd}]..."
    log "Execing the step [${cmd}]..."
    ${cmd} >>${log_file} 2>&1
    if [ $? -eq 0 ];then
        echo -n "OK." && echo ""
        log "Exec the step [${cmd}] OK."
    else
        echo -n "Error!" && echo ""
        log "Exec the function [${cmd}] Error!"
        exit 1
    fi
}

function main() {
    echo "===初始化系统 v0.1==="

    if [ `id -u` -ne 0 ];then
        echo "Not Root!!!"
        exit 1
    fi
    if [ $# -ne 1 ];then
        Usage
        exit 1
    fi
	if [[ "x$1" == "x-h" ]] || [[ "x$1" == "x--help" ]]; then
    	Usage
    	exit 1
	fi

    if [[ "x$1" == "xcommon" ]];then
        echo "===begin to common mode==="
        log "===begin to common mode==="
        SafeExec check_network
        SafeExec update_apt
        SafeExec install_package_common
        SafeExec config_service
        SafeExec update_vim
        SafeExec update_ssh
        SafeExec update_env
    elif [[ "x$1" == "xshadow" ]];then
        echo "===begin to shadow mode==="
        log "===begin to shadow mode==="
        SafeExec check_network
        SafeExec update_apt
        SafeExec install_package_shadow
        SafeExec update_ssh
        SafeExec init_shadownsocks
    else
        Usage
        exit
    fi
    echo "Done."
}

main $1