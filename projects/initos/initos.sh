#!/usr/bin/env bash
#######################################################################
#Author: kellanfan
#Created Time : Tue 28 Aug 2018 09:39:17 AM CST
#File Name: initos.sh
#Description:
#######################################################################

#######variable#########
SCRIPT=$(readlink -f $0)
CWD=$(dirname $SCRIPT)
DATA_DIR=$CWD/data
CONF_DIR=$CWD/conf
. $CONF_DIR/common.conf
log_file=/var/log/initos.log
########################
Usage() {
    echo "$0 [common|shadow]"
    echo "  common: 普通模式安装"
    echo "  shadow: 翻墙模式安装"
    echo "Example: $0 common"
    echo "Example: $0 shadow"
}

check_network() {
    ping -c 1 -w 3 www.baidu.com > /dev/null
    if [ $? -ne 0 ];then
        echo "网络不通！！！"
        exit
    fi
}

log() {
    msg=$*
    DATE=$(date +'%Y-%m-%d %H:%M:%S')
    echo "${DATE} ${msg}" >> ${log_file}
}

update_ssh() {
    echo "====更新ssh配置===="
    if [ -d /root/.ssh ];then
        rm -rf /root/.ssh
    fi
    cp -r $DATA_DIR/ssh /root/.ssh
    sed -i "/^Port/s/22/${ssh_port}/" /etc/ssh/sshd_config
    sed -i '/^#PasswordAuthentication/a\PasswordAuthentication no' /etc/ssh/sshd_config
    service ssh restart
}

#update apt
update_apt() {
    local os_version=$(cat /etc/issue|awk '{print $2}'|cut -d'.' -f 1)
    echo "====更新apt源===="
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
update_env() {
    echo "====更新环境变量===="
    cat <<EOF >> /root/.bashrc
PS1="\u@\[\e[1;93m\]\h\[\e[m\]:\w\\$\[\e[m\] "
HISTTIMEFORMAT="%F %T `whoami` "
export PYTHONDONTWRITEBYTECODE=False
export WORKON_HOME=$HOME/.virtualenvs
source /usr/local/bin/virtualenvwrapper.sh
EOF
}

update_vim() {
    echo "====更新vimrc配置===="
    git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
    cp $DATA_DIR/vimrc ~/.vimrc
    cp $DATA_DIR/vimrc.bundles ~/.vimrc.bundles
}

install_package_1() {
    #install package
    echo "====安装相关软件===="
    apt-get install -y -qq vim openssh-server git python-pip python3-pip ipython ipython3 ctags
    curl -sSL https://get.daocloud.io/docker | sh
    #pip install
    pip install virtualenv
    pip install virtualenvwrapper
}

init_shadownsocks() {
    echo "====安装shadowsocks===="
    pip install shadowsocks

    #unzip $CWD/data/shadowsocks-master.zip
    #cd $CWD/data/shadowsocks-master
    #python setup.py install
	if [ ! -d /etc/shadowsocks ];then
		mkdir /etc/shadowsocks
	fi
    cp $CWD/data/config.json /etc/shadowsocks/
    /usr/local/bin/ssserver -c /etc/shadowsocks/config.json -k Zhu88jie -d start
    sed -i "/^exit/i\/usr/local/bin/ssserver -c /etc/shadowsocks/config.json -k Zhu88jie -d start" /etc/rc.local
}


install_package_2() {
    echo "====安装相关软件===="
	apt-get install -y -qq unzip openssh-server python-pip python3-pip
	pip install virtualenv
	pip install virtualenvwrapper
}


main() {
    echo "===初始化系统 v0.1==="

    if [ `id -u` -ne 0 ];then
        echo "Not Root!!!"
        exit
    fi
    if [ $# -ne 1 ];then
        Usage
        exit
    fi
	if [[ "x$1" == "x-h" ]] || [[ "x$1" == "x--help" ]]; then
    	Usage
    	exit 1
	fi

    check_network

    if [[ "x$1" == "xcommon" ]];then
        echo "开始部署常规模式"
        update_apt
        install_package_1
        update_vim
        update_ssh
        update_env
    elif [[ "x$1" == "xshadow" ]];then
        echo "开始部署翻墙模式"
        update_apt
        install_package_2
        update_ssh
        init_shadownsocks
        update_env
    else
        Usage
        exit
    fi
    echo "Done."
}

main $1
