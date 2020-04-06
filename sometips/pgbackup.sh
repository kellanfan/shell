#######################################################################
#Author: Kellan Fan
#Created Time : Sat 07 Mar 2020 09:34:43 PM CST
#File Name: pgbackup.sh
#Description:
#######################################################################
#!/bin/bash

SCRIPT=$(readlink -f $0)
CWD=$(dirname ${SCRIPT})
CONF_FILE=${CWD}/pgbackup.conf


backup() {
    export PGPASSWORD
    pg_dumpall -Upostgres -h ${postgres_host} > ${LOCAL_BACKUP_DIR}/pg_full_backup_$(date +%Y%m%d).sql 
    if [ $? -eq 0 ];then
        logger "本地备份完成..."
    else
        logger "本地备份失败..."
    fi
}

cleanup() {
    count=`ls -1 ${LOCAL_BACKUP_DIR} |wc -l`
	if [ ${count} -gt ${max_dump_num} ]; then
		delnum=`expr ${count} - ${max_dump_num}`
		cd ${LOCAL_BACKUP_DIR}
        for file in $(ls -1t ${LOCAL_BACKUP_DIR} | tail -$delnum);do
            /usr/local/bin/qsctl rm qs://${BUCKET_NAME}/pgbackup/${file} >> /var/log/syslog
        done
		ls -1t ${LOCAL_BACKUP_DIR} | tail -$delnum | xargs rm -f
	fi
}

push_oss() {
    /usr/local/bin/qsctl sync ${LOCAL_BACKUP_DIR} qs://${BUCKET_NAME}/pgbackup/ >> /var/log/syslog
    if [ $? -eq 0 ]; then
        logger "远程推送备份文件成功.."
    else
        logger "远程推送备份文件失败.."
    fi
}

main() {
    if [ -f "${CONF_FILE}" ];then
        . ${CONF_FILE}
    else
        echo "The config file [${CONF_FILE}] not exist.."
        exit 1
    fi

    if [ ! -d "${LOCAL_BACKUP_DIR}" ];then
        mkdir ${LOCAL_BACKUP_DIR}
    fi

    if [ ${UID} != 0 ];then
        echo "please run by uesr root..."
        exit 1
    fi

    logger '======开始备份postgresql======'
    backup
    cleanup
    push_oss
    logger '======备份postgresql完成======'
}

main