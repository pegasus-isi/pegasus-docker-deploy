#!/bin/bash

AMAZON_FILE_PATH=$1
BUILD_PEGASUS_FILE_PATH=$2
NODES=$3

if [ $# -le 2 ]
then
    echo "Error: Usage must be ./pegasus-docker-deploy.sh [path_to_aws_configuration_file] [path_to_pegasus_docker_builder_file] [number_of_worker_nodes]"
    exit 1
fi

# read the amazon ec2 configurations from a file and assign enviroment variables
# the amazon configuration file's path must be the first argument of this script
while read line; do
    echo export $line
    export $line
done < $AMAZON_FILE_PATH

#1 - create key-value store
echo "—————Launching pegasus-keystore host"
docker-machine create -d amazonec2 pegasus-keystore

# Open the required ports:
# 8500 will be used by the key-value store
# 7946 (TCP and UDP) and 4789 will be used by the overlay network
# 9618 will be used by Condor
DOCKER_SG_ID="$(aws ec2 describe-security-groups | grep -A 3 "docker-machine" | grep "GroupId" | sed -n 's/"GroupId": "\(.*\)\"/\1/gp' | sed -n 's/ //gp')"
echo "docker-machine security group id: $DOCKER_SG_ID"
echo "Opening required ports"
aws ec2 authorize-security-group-ingress --group-id $DOCKER_SG_ID --protocol tcp --port 8500 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $DOCKER_SG_ID --protocol tcp --port 7946 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $DOCKER_SG_ID --protocol tcp --port 9618 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $DOCKER_SG_ID --protocol udp --port 7946 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $DOCKER_SG_ID --protocol udp --port 4789 --cidr 0.0.0.0/0


eval "$(docker-machine env pegasus-keystore)"

echo "—————Running consul container over pegasus-keystore host"
docker run -d -p "8500:8500" -h "consul" progrium/consul -server -bootstrap


# 2 - create swarm cluster

# create swarm master host
echo '----------Launching swarm manager host (pegasus-submit-node)'
docker-machine create -d amazonec2 --swarm --swarm-master --swarm-discovery="consul://$(docker-machine ip pegasus-keystore):8500" --engine-opt="cluster-store=consul://$(docker-machine ip pegasus-keystore):8500" --engine-opt="cluster-advertise=eth0:2376" pegasus-submit-node

# create swarm workers hosts
i=1
while [ $i -le $NODES ]; do
    echo '—————Launching swarm worker$i host (pegasus-worker$i)'
    docker-machine create -d amazonec2 --swarm --swarm-discovery="consul://$(docker-machine ip pegasus-keystore):8500" --engine-opt="cluster-store=consul://$(docker-machine ip pegasus-keystore):8500" --engine-opt="cluster-advertise=eth0:2376" pegasus-worker$i
    let i=i+1
done

# 3 - create the overlay network
eval $(docker-machine env --swarm pegasus-submit-node)
echo "—————Creating overlay network"

docker network create --driver overlay --subnet=10.0.9.0/24 my-net

# 4 - Run application on swarms hosts using the overlay network

# copy the dockerfiles to the swarm master host
echo "—————Transferring Dockerfiles to swarm hosts"
docker-machine scp $BUILD_PEGASUS_FILE_PATH pegasus-submit-node:/home/ubuntu/build.sh

i=1
while [ $i -le $NODES ]; do
    echo "Copying Dockerfile to pegasus-worker$i"
    docker-machine scp $BUILD_PEGASUS_FILE_PATH pegasus-worker$i:/home/ubuntu/build.sh
    let i=i+1
done

# create pegasus docker images.
echo "—————Building pegasus:submit image on pegasus-submit-node host"
docker-machine ssh pegasus-submit-node chmod a+x build.sh
docker-machine ssh pegasus-submit-node ./build.sh

echo "—————Building pegasus:worker image on workers hosts"
i=1
while [ $i -le $NODES ]; do
    echo "—————Building pegasus:worker image on worker$i host"
    docker-machine ssh pegasus-worker$i chmod a+x build.sh
    docker-machine ssh pegasus-worker$i ./build.sh worker
    let i=i+1
done

# run condor head container on submit host
eval $(docker-machine env --swarm pegasus-submit-node)
echo "—————Running pegasus submit container on pegasus-submit-node host"
docker run -itd -h submit --name=submit --net=my-net -e constraint:node==pegasus-submit-node pegasus:submit

# run condor worker container workers hosts
i=1
while [ $i -le $NODES ]; do
    echo "----------Running pegasus worker container on pegasus-worker$i host"
    docker run -itd -h worker$i --name=worker$i --net=my-net -e constraint:node==pegasus-worker$i pegasus:worker
    let i=i+1
done


#open the submit container’s bash
echo '----------Logging into the pegasus submit container'
docker exec -it submit bash
