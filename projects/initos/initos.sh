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

if [ `id -u` -ne 0 ];then
    echo "Not Root!!!"
    exit
fi

######update vimrc#########
update_vim() {
    cp /etc/vim/vimrc /etc/vim/vimrc-bak
    cp $DATA_DIR/vimrc /etc/vim/vimrc
    source /etc/vim/vimrc > /dev/null
}

#update ssh-key
update_ssh() {
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
    cp /etc/apt/sources.list /etc/apt/sources.list-bak
    cp $DATA_DIR/sources.list /etc/apt/sources.list
    apt-get clean; apt-get autoclean;
    apt-get update
    #install package
    apt-get -y install git docker.io mysql-server-5.6 python-pip python3-pip ipython ipython3

    #pip install
    pip install virtualenv
    pip install virtualenvwrapper
}

#update env
update_env() {
    cat <<EOF >> /root/.bashrc
PS1="\u@\[\e[1;93m\]\h\[\e[m\]:\w\\$\[\e[m\] "
HISTTIMEFORMAT="%F %T `whoami` "
export PYTHONDONTWRITEBYTECODE=False
export WORKON_HOME=$HOME/.virtualenvs
source /usr/local/bin/virtualenvwrapper.sh
EOF
}

main() {
    #update_vim
    update_ssh
    #update_apt
    #update_env
}

main
