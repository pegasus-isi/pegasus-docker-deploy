#!/bin/bash

ROOT=$1

eval $(docker-machine env --swarm pegasus-submit-node)

if [ "$ROOT" = "root" ]
then
    docker exec -it -u 0 submit bash 
else
    docker exec -it submit bash
fi
