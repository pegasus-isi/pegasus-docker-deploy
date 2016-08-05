#!/bin/bash

NODES=$1

if [ $# -eq 0 ]
then
    echo "Usage: ./pegasus-docker-deploy-terminate.sh [number of WORKER nodes]"
else
    docker-machine rm -f pegasus-keystore pegasus-submit-node

    i=1
    while [ $i -le $NODES ]; do
        docker-machine rm -f pegasus-worker$i
        let i=i+1
    done
fi
