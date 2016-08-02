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
    DEST=.
fi

if [ $exit -eq 0 ]
then
    eval $(docker-machine env --swarm pegasus-submit-node)
    docker-machine ssh pegasus-submit-node mkdir scratch
    docker-machine ssh pegasus-submit-node sudo docker cp submit:$SOURCE /home/ubuntu/scratch/transferredFiles
    docker-machine scp -r pegasus-submit-node:/home/ubuntu/scratch/transferredFiles $DEST
    docker-machine ssh pegasus-submit-node sudo rm -r scratch
fi
