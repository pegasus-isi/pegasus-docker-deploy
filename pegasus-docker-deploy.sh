#!/bin/bash

AMAZON_FILE_PATH=$1
BUILD_PEGASUS_FILE_PATH=$2
NODES=$3

# read the amazon ec2 configurations from a file and assign enviroment variables
# the amazon configuration file's path must be the first argument of this script
while read line; do
    if [ "$line" != "[default]" ]
    then
        echo export $line
        export $line
    fi
done < $AMAZON_FILE_PATH

#1 - create key-value store
echo -----------Creating consul host
docker-machine create -d amazonec2 pegasus-keystore

# Open the required ports:
# 8500 will be used by the key-value store
# 7946 (TCP and UDP) and 4789 will be used by the overlay network
# 9618 will be used by Condor
DOCKER_SG_ID="$(aws ec2 describe-security-groups | grep -A 3 "docker-machine" | grep "GroupId" | sed -n 's/"GroupId": "\(.*\)\"/\1/gp' | sed -n 's/ //gp')"
echo docker-machine security group id: $DOCKER_SG_ID
echo Opening required ports
aws ec2 authorize-security-group-ingress --group-id $DOCKER_SG_ID --protocol tcp --port 8500 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $DOCKER_SG_ID --protocol tcp --port 7946 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $DOCKER_SG_ID --protocol tcp --port 9618 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $DOCKER_SG_ID --protocol udp --port 7946 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $DOCKER_SG_ID --protocol udp --port 4789 --cidr 0.0.0.0/0


eval "$(docker-machine env pegasus-keystore)"

# TODO: try to fix this some other way
export DOCKER_API_VERSION=1.23

echo ----------Running consul container
docker run -d -p "8500:8500" -h "consul" progrium/consul -server -bootstrap


# 2 - create swarm cluster

# create swarm master host
echo ----------Creating swarm master host
docker-machine create -d amazonec2 --swarm --swarm-master --swarm-discovery="consul://$(docker-machine ip pegasus-keystore):8500" --engine-opt="cluster-store=consul://$(docker-machine ip pegasus-keystore):8500" --engine-opt="cluster-advertise=eth0:2376" pegasus-submit-node

# create swarm wokers hosts
i=1
while [ $i -le $NODES ]; do
    echo ----------Creating swarm worker$i host
    docker-machine create -d amazonec2 --swarm --swarm-discovery="consul://$(docker-machine ip pegasus-keystore):8500" --engine-opt="cluster-store=consul://$(docker-machine ip pegasus-keystore):8500" --engine-opt="cluster-advertise=eth0:2376" pegasus-worker$i
    let i=i+1
done

# 3 - create the overlay network
eval $(docker-machine env --swarm pegasus-submit-node)
echo ----------Creating overlay network

docker network create --driver overlay --subnet=10.0.9.0/24 my-net

# check if it is created correctly
docker network ls

# 4 - Run application on swarms hosts using the overlay network

# copy the dockerfiles to the swarm master host
echo ----------Transferring dockerfiles to swarm hosts
docker-machine scp $BUILD_PEGASUS_FILE_PATH pegasus-submit-node:/home/ubuntu/build.sh

i=1
while [ $i -le $NODES ]; do
    echo Copying Dockerfile to pegasus-worker$i
    docker-machine scp $BUILD_PEGASUS_FILE_PATH pegasus-worker$i:/home/ubuntu/build.sh
    let i=i+1
done

# create pegasus docker images.
echo ----------Building pegasus:submit image on submit host
docker-machine ssh pegasus-submit-node chmod a+x build.sh
docker-machine ssh pegasus-submit-node ./build.sh

echo ----------Building pegasus:worker image on workers hosts
i=1
while [ $i -le $NODES ]; do
    echo ----------Building pegasus:worker$i image
    docker-machine ssh pegasus-worker$i chmod a+x build.sh
    docker-machine ssh pegasus-worker$i ./build.sh worker
    let i=i+1
done

# run condor head container on submit host
eval $(docker-machine env --swarm pegasus-submit-node)
echo ----------Running pegasus submit container on swarm master host
docker run -itd -h submit --name=submit --net=my-net -e constraint:node==pegasus-submit-node pegasus:submit

# run condor worker container workers hosts
i=1
while [ $i -le $NODES ]; do
    echo ----------Running pegasus worker container on swarm worke$ir host
    docker run -itd -h worker$i --name=worker$i --net=my-net -e constraint:node==pegasus-worker$i pegasus:worker
    let i=i+1
done


#open the condor head container’s bash and run the tutorial
#note: to try the tutorial we need to set USER=‘tutorial’ and comment the lines regarding metadata on the daxgen.py file
echo ----------Logging into the pegasus head container
docker exec -it submit bash

# OBS:
# 1 - Docker API VERSION
# 2 - Security group
# 3 - pegasus-init bug (USER='tutorial')





