#!/bin/bash
##############################################################
#Author: Kellan Fan
#Created Time : Fri 10 Jul 2020 01:26:07 PM CST
#File Name: install-k8s.sh
#Description:
##############################################################

#### common variable ####

SCRIPT=$(readlink -f $0)
CWD=$(dirname ${SCRIPT})
LOG_FILE=/var/log/install_k8s.log

function prepare() {
    ping -c 1 -w 1 www.baidu.com > /dev/null
    if [ $? -ne 0 ]; then
        echo "Can not connect internet..."
        exit 1
    fi
    systemctl stop ufw
    swapoff -a
    sed -i '/SWAP/s/^/#/' /etc/fstab
    sed -i '/swap/s/^/#/' /etc/fstab
    grep 'kubectl completion bash' /root/.bashrc || echo "source <(kubectl completion bash)" >> /root/.bashrc
}

function stop_apt_daily() {
    apt-get -y purge unattended-upgrades snapd
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

function modify_dns(){
    systemctl disable systemd-resolved 
    systemctl stop systemd-resolved 
    rm /etc/resolv.conf
    touch /etc/resolv.conf
    echo "nameserver 114.114.114.114" >> /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
}

function update_repo() {
    echo "Update repo..."
    cat > /etc/apt/sources.list << EOF
deb http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
EOF
    echo "deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main" > /etc/apt/sources.list.d/k8s.list
    curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
    apt-get update && apt-get install -y apt-transport-https
}

function mount_data() {
    mkdir -p /data/docker
    mount /dev/vdc1 /data/docker
}

function install_common_package() {
    echo "install common packages..."
    apt install -y etcd-client ipset conntrack nfs-common
}
function install_docker() {
    echo "install docker..."
    apt install -y docker.io
    cat > /etc/docker/daemon.json << EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "insecure-registries": ["10.90.25.5"],
  "data-root": "/data/docker",
  "registry-mirrors": ["http://hub-mirror.c.163.com", "https://registry.docker-cn.com"]
}
EOF
    systemctl daemon-reload
    systemctl restart docker
    systemctl enable docker
}

function install_kube() {
    echo "install kube..."
    apt-get install -y kubelet=${KUBE_VERSION}-00 kubeadm=${KUBE_VERSION}-00 kubectl=${KUBE_VERSION}-00
    systemctl daemon-reload
    systemctl enable kubelet
}

function pull_images() {
    echo "Pull images..."
    for image in $(kubeadm config images list | awk -F'io/' '{print $2}');do
        if [[ ${image} =~ coredns ]];then
            IMAGE_VERSION=$(echo ${image} | awk -F'/' '{print $2}')
            docker pull registry.aliyuncs.com/google_containers/${IMAGE_VERSION} || docker pull registry.aliyuncs.com/google_containers/coredns
            CUR_VERSION=$(docker images| grep google_containers/coredns | awk '{print $2}')
            docker tag registry.aliyuncs.com/google_containers/coredns:${CUR_VERSION} k8s.gcr.io/${image}
            docker rmi registry.aliyuncs.com/google_containers/coredns:${CUR_VERSION}
        else
            docker pull registry.aliyuncs.com/google_containers/${image}
            docker tag registry.aliyuncs.com/google_containers/${image} k8s.gcr.io/${image}
            docker rmi registry.aliyuncs.com/google_containers/${image}
        fi
    done
}

function init_k8s() {
    echo "Init k8s..."
    #KUBE_VERSION=$(kubeadm config images list |grep kube-apiserver| awk -F'/|:' '{print $3}')
    kubeadm init  --kubernetes-version=${KUBE_VERSION} --service-cidr=10.96.0.0/12 --pod-network-cidr=10.96.0.0/16  --ignore-preflight-errors=Swap
    mkdir -p /root/.kube
    cp -i /etc/kubernetes/admin.conf /root/.kube/config
    chown root.root /root/.kube/config
}

function install_calico() {
    echo "Install calico..."
    kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/tigera-operator.yaml
    wget https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/custom-resources.yaml
    sed -i '/cidr/s/192.168/10.96/' custom-resources.yaml
    kubectl apply -f custom-resources.yaml
}

function install_harbor() {
    wget https://github.com/goharbor/harbor/releases/download/v2.0.1/harbor-online-installer-v2.0.1.tgz
    tar zxf harbor-online-installer-v2.0.1.tgz -C /opt
    docker-compose --version > /dev/null
    if [ $? -ne 0 ];then
        wget https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m) -O /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    mv /opt/harbor/harbor.yml.tmpl /opt/harbor/harbor.yml
    ip=$(ifconfig eth0 |grep 'inet '| awk '{print $2}')
    sed -i "/hostname/s/reg.mydomain.com/${ip}/" /opt/harbor/harbor.yml
    sed -i '12,18d' /opt/harbor/harbor.yml
    cd /opt/harbor
    ./install.sh
}

function untaint_master() {
    kubectl taint node $(hostname) node-role.kubernetes.io/master:NoSchedule-
}

function join_cluster() {
    part1=$(ssh ${MASTER_IP} "grep 'kubeadm join' /var/log/install_k8s.log | tr '\' ' '")
    part2=$(ssh ${MASTER_IP} "grep 'discovery-token-ca-cert-hash' /var/log/install_k8s.log")
    join_cmd="${part1} ${part2}"
    #join_cmd="ssh ${MASTER_IP} kubeadm token create --print-join-command"
    ${join_cmd}
}

function SafeExec() {
    local cmd=$1
    echo -n "Execing the step [${cmd}]..."
    log "Execing the step [${cmd}]..."
    grep ${cmd} ${SCRIPT}.flag > /dev/null
    if [ $? -eq 0 ];then
        echo -n "Skip." && echo ""
    else
        ${cmd} >>${LOG_FILE} 2>&1
        if [ $? -eq 0 ];then
            echo -n "OK." && echo ""
            log "Exec the step [${cmd}] OK."
            echo ${cmd} >> ${SCRIPT}.flag
        else
            echo -n "Error!" && echo ""
            log "Exec the function [${cmd}] Error!"
            exit 1
        fi
    fi
}

function log() {
    msg=$*
    DATE=$(date +'%Y-%m-%d %H:%M:%S')
    echo "${DATE} ${msg}" >> ${LOG_FILE}
}
function Usage() {
    echo "$0 <master K8S_VERSION|node K8S_VERSION MASTER_IP>"
}

function main() {
    if [ `id -u` -ne 0 ];then
        echo "Not Root!!!"
        exit 1
    fi

    if [[ "x$1" == "x-h" ]] || [[ "x$1" == "x--help" ]]; then
        Usage
        exit 1
    fi

    if [ ! -f ${SCRIPT}.flag ];then
        touch ${SCRIPT}.flag
    fi
    
    if [[ "x$1" == "xmaster" ]];then
        if [ $# -ne 2 ];then
            Usage
            exit 1
        fi
        KUBE_VERSION=$2
        SafeExec prepare
        SafeExec check_apt_process
        SafeExec update_repo
        SafeExec stop_apt_daily
        SafeExec modify_dns
        SafeExec install_common_package
        SafeExec mount_data
        SafeExec install_docker
        SafeExec install_kube
        SafeExec pull_images
        SafeExec init_k8s
        SafeExec install_calico
        SafeExec untaint_master
        #SafeExec add_role_to_coredns
        #SafeExec install_harbor
    elif [[ "x$1" == "xnode" ]];then
        if [ $# -ne 3 ];then
            Usage
            exit 1
        fi
        KUBE_VERSION=$2
        MASTER_IP=$3
        SafeExec prepare
        SafeExec check_apt_process
        SafeExec update_repo
        SafeExec stop_apt_daily
        SafeExec modify_dns
        SafeExec install_common_package
        SafeExec install_docker
        SafeExec install_kube
        SafeExec pull_images
        SafeExec join_cluster
    else
        Usage
        exit 1
    fi
}

main $@
