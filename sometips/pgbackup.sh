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
    export ${PGPASSWORD}
    pg_dumpall -Upostgres > ${LOCAL_BACKUP_DIR}/pg_full_backup_$(date +%Y%m%d).sql
    if [ $? == 0 ];then
        logger "本地备份完成..."
    else
        logger "本地备份失败..."
    fi
}

local_cleanup() {
    count=`ls -1 ${LOCAL_BACKUP_DIR} |wc -l`
	if [ ${count} -gt ${max_dump_num} ]; then
		delnum=`expr ${count} - ${max_dump_num}`
		cd ${LOCAL_BACKUP_DIR}
		ls -1t ${LOCAL_BACKUP_DIR} | tail -$delnum | xargs rm -f
	fi
}

push_oss() {
    qsctl sync ${LOCAL_BACKUP_DIR} qs://${BUCKET_NAME}/pgbackup/
    if [ $? == 0 ]; then
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
    local_cleanup
    push_oss
    logger '======备份postgresql完成======'
}

main