#!/bin/bash

SCRIPT=`readlink -f $0`
CWD=`dirname ${SCRIPT}`

function SafeExec()
{
    local cmd=$*
    ${cmd} >>install.log 2>&1
    if [ $? -ne 0 ]; then
        echo "Exec ${cmd} FAILED."
        exit 1
    fi
}


