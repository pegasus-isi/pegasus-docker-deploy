# pegasus-docker-deploy

Pegasus docker deploy is a tool to create a docker swarm cluster on the Amazon Elastic Compute Cloud (EC2) running Pegasus containers. It starts a given number of EC2 hosts, installs Docker, configures Swarm and run one docker container which has Pegasus installed on each host. This way, you can use Pegasus to run workflows using hosts located on the Amazon cloud service.

## Requirements

  * [Docker] (https://www.docker.com)
  * [Docker Machine] (https://docs.docker.com/machine/)
  * [Docker Swarm] (https://docs.docker.com/swarm/)
  * [AWS Command Line Interface] (https://aws.amazon.com/cli/)

## Create a swarm cluster
You can run the pegasus-docker-deploy.sh provinding three arguments. For example:

    ./pegasus-docker-deploy /home/users/myUser/aws_config /home/users/myUser/buildPegasusImage.sh 2 

The first argument must be the path of a configuration file with your AWS credentials and EC2 hosts preferences. The aws_config file on this repository is a example of this kind of file. The second one must be the path of the Pegasus docker image builder which is used to generate the Dockerfile and build an image from it. The buildPegasusImage.sh file can be found in this repository. The last argument is an integer representing the number of WORKER hosts you would like to create.

## AWS configuration file
This configuration file is used by the script to access your amazon EC2 account to create the cluster hosts. Every single host create on the AWS (key-value store, swarm manager and swarm workers) will have the configuration provided in this file. It is a text file which must be placed in the ~/.aws directory (~ stands for your home directory) with the name credentials and it must be formatted according to the following rule:

The file must start with the following line:

    [default]

Each following line of the file must be as follows:

    AWS_ENVIROMENT_VARIABLE=AWS_VALUE

This file requires, at least, four AWS enviroment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION, AWS_VPC_ID. Note that if you do not have a vpc on your AWS account you must create one using the AWS web interface for example.

One example of the aws configuration file would be:

    [defalt]
    AWS_ACCESS_KEY_ID=HUA62J283LAMSN8273JH
    AWS_SECRET_ACCESS_KEY=AbAhu8BnHA6hl+lakoehB7H654NnhuLkoP98mNH6
    AWS_DEFAULT_REGION=us-west-2
    AWS_VPC_ID=vpc-dapa44sx

This file can be found on this repository, named aws_config. A list of the aws enviroment variables and their default values can be found on this [link] (https://docs.docker.com/machine/drivers/aws/)


## Pegasus docker image builder file
This file is used by the pegasus-docker-deploy script to build the docker images with HTCondor and Pegasus installed. It is used to build one submit host image and many worker hosts image. The submit host image contains all HTCondor deamons installed while the worker host image contains only the master and starter ones. Also, the HTCondor's host for the worker hosts is the submit host.

To build a submit host image, the pegasus-docker-deploy script simply runs this script, without any arguments. But to build a worker host image, the pegasus-docker-deploy script runs this script with the string worker as argument.

## pegasus-docker-deploy script
First, this script creates one host on EC2 called pegasus-keystore-value using the docker-machine tool. The host's configuration will be the same as those defined on the aws configuration file. This host will be used to start the key-value store required by the overlay network. The key-value store holds information about the network. 

When the first host is created, docker-machine creates a security group called docker-machine. This is the default security group which is used by the script. It does not support other security groups. After creating the key-store value host on EC2, the script opens the required ports for the docker-machine security group so that all containers in the swarm cluster can communicate among them. 

After opening the required ports, the script starts a docker's Consul container on this host. This Consul container will act as the key-value store required by the network used by the swarm cluster. All EC2 hosts must advertise themselves to this container in order to be visible and reachable through the overlay network. 

Then, it creates many hosts on EC2 using the docker machine tool. The configuration of all of these hosts will be the same as those defined on the aws configuration file. The first host the script creates in this step is called pegasus-submit-node. This host is the swarm manager (master) and will be the host that will run the pegasus submit container.

After creating all this hosts, the script will create the overlay network, which will be used by them to communicate among themselves.

## key-value store and overlay network
## docker-machine
## docker-swarm
## how to use the cloud: eval ... docker exec ... blablabla
