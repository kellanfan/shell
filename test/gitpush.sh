#!/bin/bash
FILE=$1
TENT=$2
usage() {
    echo "Usage: $(basename $0) <file> <tent>"
    echo "   Ex: $(basename $0) aa.sh shelllearn"
}
if [ $# -lt 2 ]; then
    echo "Error: invalid parameters"
    usage
    exit 1
fi

git add $1
git commit -m "$2" 
git push origin master
