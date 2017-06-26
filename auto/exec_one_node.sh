#!/bin/bash

IFS='#' read -r -a array <<< $1

echo $array
ssh -o 'StrictHostKeyChecking no' -o 'UserKnownHostsFile /dev/null' -o ConnectTimeout=2 -o ConnectionAttempts=1  ${array[0]} ${array[1]} 

