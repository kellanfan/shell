#!/bin/bash
##############################################################
#Author: Kellan Fan
#Created Time : Wed 02 Sep 2020 04:32:59 PM CST
#File Name: k8s-user.sh
#Description: 创建k8s账户
##############################################################
SCRIPT=$(readlink -f $0)
CWD=$(dirname ${SCRIPT})
LOG_FILE="/var/log/create_k8suser.log"
K8S_NAME=$(kubectl config get-clusters | tail -n 1)
CONF_FILE=${CWD}/user.conf
if [ -f ${CONF_FILE} ];then
    . ${CONF_FILE}
else
	echo "ERROR: Can not find config [${CONF_FILE}]"
	exit 1
fi

function download_cfssl() {
    if [ ! -f /usr/local/bin/cfssl ];then
        wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
        wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
        wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
        mv cfssl_linux-amd64 /usr/local/bin/cfssl
        mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo
        mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
        chmod +x /usr/local/bin/*
    fi
}

function gercert() {
    cd /etc/kubernetes/pki/
    [ -f /etc/kubernetes/pki/${USER_NAME}.pem ] && rm /etc/kubernetes/pki/${USER_NAME}.pem
    [ -f /etc/kubernetes/pki/${USER_NAME}-key.pem ] && rm /etc/kubernetes/pki/${USER_NAME}-key.pem
    cfssl gencert -ca=ca.crt -ca-key=ca.key -profile=kubernetes ${CWD}/${CERT_JSON} | cfssljson -bare ${USER_NAME}
}

function create_user() {
    id ${USER_NAME} > /dev/null
    if [ $? -ne 0 ];then
        useradd -m -s /bin/bash -p ${USER_PASS} ${USER_NAME}
        mkdir /home/${USER_NAME}/.kube
    fi
}

function kube_config() {
    cd ${CWD}
    [ -f ${KUBE_USER_CONFIG_FILE} ] && rm ${KUBE_USER_CONFIG_FILE}

    # 设置集群参数
    kubectl config set-cluster ${K8S_NAME} \
    --certificate-authority=/etc/kubernetes/pki/ca.crt \
    --embed-certs=true --server=${KUBE_APISERVER} \
    --kubeconfig=${KUBE_USER_CONFIG_FILE}

    # 设置客户端认证参数
    kubectl config set-credentials devuser \
    --client-certificate=/etc/kubernetes/pki/${USER_NAME}.pem \
    --client-key=/etc/kubernetes/pki/${USER_NAME}-key.pem \
    --embed-certs=true --kubeconfig=${KUBE_USER_CONFIG_FILE}
    kubectl get ns | grep ${NAMESPACE} > /dev/null || kubectl create namespace ${NAMESPACE}

    # 设置上下文参数
    kubectl config set-context ${CONTEXT_NAME} \
    --cluster=${K8S_NAME} \
    --user=${USER_NAME} \
    --namespace=${NAMESPACE} \
    --kubeconfig=${KUBE_USER_CONFIG_FILE}

    # 设置默认上下文
    cp -f ${CWD}/${KUBE_USER_CONFIG_FILE} /home/${USER_NAME}/.kube/config
    chown -R ${USER_NAME}.${USER_NAME} /home/${USER_NAME}/.kube
    kubectl get rolebinding -n ${NAMESPACE} | grep ${USER_NAME}-binding > /dev/null
    if [ $? -ne 0 ];then
        kubectl delete rolebinding -n ${NAMESPACE} ${USER_NAME}-binding
        kubectl create rolebinding \
        ${USER_NAME}-binding --clusterrole=${ROLE} \
        --user=${USER_NAME} --namespace=${NAMESPACE}
    fi
    #kubectl config use-context kubernetes --kubeconfig=${KUBE_USER_CONFIG_FILE}
}

function check_network() {
    ping -c 1 -w 3 -4 www.baidu.com > /dev/null
    if [ $? -ne 0 ];then
        exit 1
    fi
}

function log() {
    msg=$*
    DATE=$(date +'%Y-%m-%d %H:%M:%S')
    echo "${DATE} ${msg}" >> ${LOG_FILE}
}

function SafeExec() {
    local cmd=$1
    echo -n "Execing the step [${cmd}]..."
    log "Execing the step [${cmd}]..."
    ${cmd} >>${LOG_FILE} 2>&1
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
    SafeExec check_network
	SafeExec download_cfssl
	SafeExec create_user
	SafeExec gercert
	SafeExec kube_config
}

main