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
export DEBIAN_FRONTEND
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
    sed -i "/Port/aPort ${ssh_port}" /etc/ssh/sshd_config
    sed -i '/^#PasswordAuthentication/a\PasswordAuthentication no' /etc/ssh/sshd_config
    service ssh reload
}

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

function update_env() {
    echo "===update env==="
    if [ ! -d /root/.backup ];then
        mkdir /root/.backup
    fi
    cat ${DATA_DIR}/bashrc >> ~/.bashrc
    cat ${DATA_DIR}/profile >> /etc/profile
}

function update_vim() {
    echo "===update vimrc==="
    cp ${DATA_DIR}/vimrc ~/.vimrc
}

function install_package_common() {
    echo "===install packages==="  
    check_apt_process
    apt-get install -y git python3-pip ipython3 redis etcd mongodb postgresql
    curl -sSL https://get.daocloud.io/docker | sh
    pip3 install virtualenv
    pip3 install virtualenvwrapper
}

function stop_apt_daily() {
    apt-get -y remove unattended-upgrades
    systemctl kill --kill-who=all apt-daily.service
    systemctl stop apt-daily.timer
    systemctl disable apt-daily.timer
    systemctl stop apt-daily.service
    systemctl disable apt-daily.service
    systemctl mask apt-daily.service
    systemctl daemon-reload
}

function check_apt_process() {
    echo "Check apt process, Make sure there is no apt process"
    while true;do
        kill -9 $(pgrep apt)
        sleep 1
        pgrep apt > /dev/null
        if [ $? -ne 0 ]; then
            break
        fi
    done
    rm /var/lib/apt/lists/lock
    rm /var/cache/apt/archives/lock
    rm /var/lib/dpkg/lock
}

function install_package_shadow() {
    echo "===install packages==="
    check_apt_process
    apt-get install -y -qq python3-pip
}

function init_shadownsocks() {
    echo "===install shadowsocks==="
    pip3 install shadowsocks
	if [ ! -d /etc/shadowsocks ];then
		mkdir /etc/shadowsocks
	fi
    cp ${DATA_DIR}/shadowsocks/config.json /etc/shadowsocks/
    sed -i "/password/s/xxxxxx/${shadow_password}/" /etc/shadowsocks/config.json
    sed -i 's/cleanup/reset/' /usr/local/lib/python3.6/dist-packages/shadowsocks/crypto/openssl.py
    cp ${DATA_DIR}/shadowsocks/shadowsocks.service /lib/systemd/system/
    systemctl daemon-reload
    systemctl start shadowsocks.service
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
    echo "===初始化系统 v0.2==="

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
        SafeExec stop_apt_daily
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
        SafeExec stop_apt_daily
        SafeExec update_ssh
        SafeExec init_shadownsocks
    else
        Usage
        exit
    fi
    echo "Done."
}

main $1