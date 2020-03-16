#!/bin/bash
#######################################################################
#Author: kellanfan
#Created Time : Tue 16 Mar 2020 09:39:17 AM CST
#File Name: gen_cert.sh
#Description: 生成自签名证书

# expamlpe config file
# The directory of certificate
#CERT_DIR="/opt/cert"
# The password of certificate
#CERT_PASS="Zhu88jie"
# The Country Name
#Country_Name="CN"
# The State or Province Name
#State="BJ"
# Locality Name
#Locality_Name="BJ"
# Organization Name
#Organization_Name="example"
# Organizational Unit Name
#Organizational_Unit_Name="dev"
# Common Name
#Common_Name="example.com"
# Email Address
#Email_Address="test@example.com"

#######################################################################

SCRIPT=$(readlink -f $0)
CWD=$(dirname ${SCRIPT})
CONF_FILE=${CWD}/gen_cert.conf

gen_cert() {
    echo "Begin to genrate cert.."
    cd ${CERT_DIR}
    openssl genrsa -des3 -passout pass:${CERT_PASS} -out server-key.pem 2048
    openssl req -new -key server-key.pem -out server.csr -passin pass:${CERT_PASS} -subj "/C=${Country_Name}/ST=${State}/L=${Locality_Name}/O=${Organization_Name}/OU=${Organizational_Unit_Name}/CN=${Common_Name}/emailAddress=${Email_Address}"
    openssl rsa -in server-key.pem -out server_no_passwd-key.pem -passin pass:${CERT_PASS}
    openssl x509 -req -days 3650 -in server.csr -signkey server_no_passwd-key.pem -out server-chained.pem
    mv server_no_passwd-key.pem server-key.pem
    cat server-chained.pem server-key.pem > server.pem
    rm server.csr
    echo "Genrate cert successfully.."
}

if [ ! -f ${CONF_FILE} ];then
    echo "Error: the conf file [${CONF_FILE}] is NOT EXISTS!"
    exit 1
else
    . ${CONF_FILE}
fi

if [ ! -d ${CERT_DIR} ];then
    mkdir ${CERT_DIR}
fi
gen_cert
echo "Done"
