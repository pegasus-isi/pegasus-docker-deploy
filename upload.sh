#!/bin/bash

SOURCE=$1
DEST=$2
exit=0

if [ $# -eq 0 ]
then
    echo "Usage: ./upload.sh [source] [destination]"
    exit=1
elif [ $# -eq 1 ]
then
    DEST="/home/tutorial/"
fi

if [ $exit -eq 0 ]
then
    docker-machine ssh pegasus-submit-node mkdir scratch
    docker-machine scp -r $SOURCE pegasus-submit-node:/home/ubuntu/scratch/transferredFiles
    docker-machine ssh pegasus-submit-node sudo docker cp /home/ubuntu/scratch/transferredFiles submit:$DEST
    docker-machine ssh pegasus-submit-node sudo rm -r scratch
fi
