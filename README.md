[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

# Deploying Pegasus infrastructure with Docker Swarm

`pegasus-docker-deploy` is a tool to create a Docker Swarm cluster scheduling and running Pegasus Docker containers. Currently, the tools provides support to the following systems:

* VirtualBox
* Amazon Elastic Compute Cloud (EC2)
* Google Cloud Platform

In a nutshell, the tool starts a given number of virtual machine (VM) hosts, installs Docker, configures Swarm, and run one docker container which has Pegasus installed on each host.

This tool will start two required hosts and a number of worker (compute) nodes as specified by the user. The required hosts are: (1) the `pegasus-keystore`, which runs a key-value store [Consul](https://hub.docker.com/r/progrium/consul/) container; and (2) the `pegasus-submit-node`, which runs a Pegasus submit Docker container. 


### Minimum requirements

* [Docker](https://www.docker.com)
* [Docker Machine](https://docs.docker.com/machine/)
* [Docker Swarm](https://docs.docker.com/swarm/)


### Overview of commands and general options

**`pegasus-docker-deploy`**: Creates a Docker swarm cluster running Pegasus Docker containers. Default behavior creates a Docker Swarm cluster in VirtualBox with a single worker (compute) node.

- `-d <DRIVER>` or `--driver <DRIVER>`: Driver to create machine with: virtualbox, amazonec2, google (default: _virtualbox_)
- `-n <NUM_NODES>` or `--nodes <NUM_NODES>`: Number of worker nodes (default: 1)
- `-c <CONF_FILE>` or `--conf <CONF_FILE>`: Configuration file: environment variables to that will be automatically exported. (default: _pegasus-docker.conf_)
- `-o <LOG_FILE>` or `--output <LOG_FILE>`: Output log file (default: _pegasus-docker.log_)
- `-i <SUBMIT_IMAGE>` or `--submit-image SUBMIT_IMAGE`: Docker image for submit node--can be customized with a pre-installed application or workflow (default: _pegasusdocker/deploy:submit-centos7_)
- `-h` or `--help`: Help menu

**`pegasus-docker-stop`**: Stops or terminates all instances from a Docker cluster. Default behavior stops all running instances.

- `-t` or `--terminate`: Terminate all running or stopped instances
- `-n <INSTANCE_NAME>` or `--name <INSTANCE_NAME>`: Stop/Terminate a specific instance


## Running Pegasus containers with VirtualBox

By default, the `pegasus-docker-deploy` command creates a Docker Swarm cluster in VirtualBox. It uses the [boot2docker](http://boot2docker.io/) lightweight Linux distribution as the guest OS, and deploys Pegasus Docker containers in the VMs. The following example command creates a cluster with five worker (compute) nodes:

```
./pegasus-docker-deploy -d virtualbox -n 5
```


## Running Pegasus containers with AmazonEC2

### Additional requirements

* [AWS Command Line Interface](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html). Make sure to [install](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) and [configure](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) the aws CLI. Your access key id and secret access key must be configured in order to AWS CLI work correctly.

### Additional command line options

- `-m <INSTANCE_TYPE>` or `--machine <INSTANCE_TYPE>`: Amazon EC2 instance type (default: _t2.micro_)
- `-r <REGION>` or `--region <REGION>`: The region to use when launching the instance (default: _us-east-1_)
- `-z <ZONE>` or `--zone <ZONE>`: The AWS zone to launch the instance in (default: _a_)

The example below deploys five worker nodes of type _t2.micro_ on the _us-east-1-a_ zone/region:
```
./pegasus-docker-deploy -d amazonec2 -n 5 -m t2.micro -r us-east-1 -z a
```

### AWS configuration file

The configuration file (default: `pegasus-docker.conf`) is used by the `pegasus-docker-deploy` script to access your amazon EC2 account to start the hosts. **Every single host created on the AWS (key-value store, swarm manager, and swarm workers) will have the configuration provided in this file.** It is a text file which must be formatted according to the following rules:

- Each line of the file must be as follows:
```
AWS_ENVIROMENT_VARIABLE=AWS_VALUE
```

- This file requires, at least, four AWS enviroment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`, `AWS_VPC_ID`. Note that if you do not have a _vpc_ on your AWS account, you must create one using the [AWS web interface](https://console.aws.amazon.com).

One example of the aws configuration file would be:
```
AWS_ACCESS_KEY_ID=HUA62J283LAMSN8273JH
AWS_SECRET_ACCESS_KEY=AbAhu8BnHA6hl+lakoehB7H654NnhuLkoP98mNH6
AWS_DEFAULT_REGION=us-west-2
AWS_VPC_ID=vpc-dapa44sx
```
    
An example file is provided in this repository. Note that you must replace the aws access key id and the aws secret access key with your keys (those keys are not valid and they are used just as an example). Some other useful AWS environment variables include `AWS_AMI`, `AWS_INSTANCE_TYPE`, and `AWS_SSH_USER`. A complete list of the AWS enviroment variables and their default values can be found on this [link](https://docs.docker.com/machine/drivers/aws/) under "Environment variables" column of the table within the Options section.



## Running Pegasus containers with Google Cloud Platform

### Additional requirements

- [Google Cloud SDK](http://cloud.google.com/sdk). Make sure to install and configure the `gcloud` client, and then [create a project](http://console.cloud.google.com/project). The **project ID** will be required to perform the deploy operation. You will also need to [**enable the Google Compute Engine API**](https://console.cloud.google.com/apis/api/compute-component.googleapis.com/overview).

Before running any Docker command for Google Compute Engine, you will need go through the oauth2 process:
```
gcloud auth login
```

### Additional command line options

- `-p <PROJECT_ID>` or `--project <PROJECT_ID>`: The id of your project to use when launching the instance (**required**)
- `-m <INSTANCE_TYPE>` or `--machine <INSTANCE_TYPE>`: Google instance type (default: _n1-standard-1_)
- `-z <ZONE>` or `--zone <ZONE>`: The Google zone to launch the instance in (default: _us-central1-a_)

The only required option is the `-p <PROJECT_ID>` or `--project <PROJECT_ID>`. Note that the project ID can also be set using an environment variable (`GOOGLE_PROJECT`) defined in the configuration file (e.g., `pegasus-docker.conf`). A complete list of the Google Computer Egine enviroment variables and their default values can be found on this [link](https://docs.docker.com/machine/drivers/gce/).

The example below deploys five worker nodes of type _n1-standard-1_ on the _us-central1-a_ zone for project _myproject_:

```
./pegasus-docker-deploy -d google -n 5 -p myproject -m n1-standard-1 -z us-central1-a
```

----



__The text below is still under revision__






## Pegasus' docker image builder file

This file is used by the pegasus-docker-deploy script to build the docker images with HTCondor and Pegasus installed. It is used to build one submit host image and many worker hosts image. The script first creates a Dockerfile and then build the image using the `docker build` command. The submit host image contains all HTCondor deamons running while the worker host image contains only the master and starter ones. Also, the HTCondor's host for the worker hosts is the submit host.

To build a submit host image, the pegasus-docker-deploy script simply runs this script, with no arguments. But to build a worker host image, the pegasus-docker-deploy script runs this script with the string **worker** as argument.

## How To Use the Cluster

In this section you will find basic information about how to submit workflows to pegasus, how to log into your hosts and/or containers, how to transfer files between your machine and your hosts and between your hosts and your containers and also how to terminate your cluster.

### Logging Into the Submit Container (Submiting Workflows)

In order to submit workflows to Pegasus, you must first log into the submit container and then submit your workflow. We provide a script for you to log into it. The script is called *login.sh* and it can be found in this repository. 
In order to log in as root, you should run the script with the string **root** as argument. For example:

    ./pegasus-docker-login root

If you want to log in as a user, you do not need to provide any argument. For example:

    ./pegasus-docker-login

You can find details about logging into a different container or into a amazon EC2 host in the "Advanced Usage of The Cluster" section below.

### Copying Files/Directories From Your Local Machine to Submit Container

In many cases, in order to submit workflows to Pegasus, you will need to transfer files from your local machine to the submit container. You can use the script called *upload.sh* located in this repository to do that:

    ./pegasus-docker-upload [source] [destination]

Where source is the path for the file/directory in your local machine and destination is the path to the location which the file/directory should be place within the container. The first argument is required and the second is optional. If you do not provide the destination argument, your file/directory will be placed in the home directory (/home/tutorial/). If you do want to provide a destination argument, you should specify the whole path. The tilde mark (~) will not stand for the home directory for that container. You must type /home/tutorial/ as the home directory of the container. **Note that your file/directory will be renamed to "transferredFiles" in the container.** 

For example, if you want to transfer a file called "inputs" located in your local machine whitin your home directory to a directory called "myFiles" located in the container's home directory, you should do:

    ./pegasus-docker-upload ~/inputs /home/tutorial/myFiles/

This command will create a file or a directory in the myFiles directory, which will contain the file or directory that you transferred.

### Copying Files/Directories From Submit Container to Your Local Machine

In other cases you will need to copy files from the submit container to your machine, such as the workflow's output files. We also provide a script for you to do that. It is called *download.sh* and its usage is:

    ./pegasus-docker-download [source] [destination]

Where *source* is now a path within the container for the file/directory you want to transfer and *destination* is a path whitin your local machine where you want to place the transferred files. The first argument is required and the second is optional. If you do not provide the destination argument, your file/directory will be placed in your local machine's current directory. For the source destination you must provide the full path and the tilde mark (~) will not stand for the container's home directory. You must type /home/tutorial/ as the home directory of the container. **Note that your file/directory will be renamed to "transferredFiles" in your local machine.** 

For example, if you want to transfer a file called "outputs" located in the submit container home directory to a directory called "myFiles" located in your local machine's home directory, you should do:

    ./pegasus-docker-download /home/tutorial/outputs ~/myFiles/

You can find details about copying from/to a different container or from/to a amazon EC2 host in the section "Advanced Usage of The Cluster" below.

### Terminating the Swarm Cluster

After you are done running workflows using the swarm cluster, you can terminate your amazon EC2 instances. You can do it by running the script *pegasus-docker-deploy-terminate.sh* as follows:

    ./pegasus-docker-terminate [number_of_worker_nodes]

*number_of_worker_nodes* is a required argument and it must be the same integer that you provided when you started your cluster using the pegasus-docker-deploy script. It means the number of **worker** hosts running in your cluster (it does not include neither pegasus-keystore nor pegasus-submit-node).

For example:

    ./pegasus-docker-terminate 2

You can find details about how to terminate a specific amazon EC2 host and all containers running on it in the "Advanced Usage of The Cluster" section below.

## Advanced Usage of The Cluster

In this section you will find detailed information about how to log into any amazon EC2 host and/or docker containers running on top of them, how to copy files/directories to and from these hosts and/or containers and also how to terminate a specific host/container.

The machine you run the pegasus-docker-deploy script (referred in this document as **local machine**) has Docker installed as well as each host on EC2. This mean that each machine has a different Docker Engine. So, if you run the *docker ps* command, for example, on your machine and then run the same command on a EC2 host, you will get different outputs because the Docker Engines are different. Therefore, you need to know how to send commands to a specific Docker Engine. To do so, you need to set your environment to that specific Docker Engine.

### Setting The Enviroment To a Specific Docker Engine

 You can run the following command from your local machine to set your environment to a Docker Engine running on a specific host:

    eval $(docker-machine env [options] [hostname])

One useful available option is the **--swarm** one. You must use this option to set your environment to the swarm manager machine, so that you can monitor your swarm cluster. Note that **hostname** is the name of one machine that has Docker installed. In this case, this argument must be the name of one of the EC2 machines that the pegasus-docker-deploy script started, such as *pegasus-keystore*, *pegasus-submit-node* or *pegasus-worker1*. **You can list what are the availables hostnames running the following command from your local machine:**

    docker-machine ls

This command will list all hosts created by docker-machine tool. You can also check to which Docker Engine your enviroment is set to, looking at the *active* column of the output. If the value of that column is a asterisk (*), it means that your enviroment is set to that host. If there are any asterisk in that column, only dashes (-) it means that your enviroment is set to the Docker Engine installed on your local machine.

Therefore, if you want to send Docker commands to the Docker Engine located on the swarm manager, first you need to do:

    eval $(docker-machine env --swarm pegasus-submit-node)

Then you are set to start sending Docker commands to that Docker Engine. If you run the *docker-machine ls* command, you should be able to see that the value for the column *active* of the pegasus-submit-node is now an asterisk.

Also, if you want to send Docker commands to the swarm nodes or to the key-value store, you should use one of the commands below:

    eval $(docker-machine env pegasus-worker1)

    eval $(docker-machine env pegasus-keystore)

Finally, if you want to undo the changes in your enviroment in order to communicate with the Docker Machine installed on your local machine, you can use that command with the option *-u* and without any hostname:

    eval $(docker-machine env -u)

Then, if you run the *docker-machine ls* command, you should see that all values for the *active* column are dashes, meaning that you are pointing to the Docker Engine installed on your local machine.

You can find more information about the *docker-machine env* command in this [link] (https://docs.docker.com/machine/reference/env/)

### Logging Into a Amazon EC2 Host

If you want to log into a Amazon EC2 host, first you need to set your enviroment to the Docker Engine installed on your local machine, as explained above, using the command:

    eval $(docker-machine env -u)

Then, you must use the *docker-machine ssh* command as follows:

    docker-machine ssh [hostname]

Hostname is the name of one amazon EC2 host available, started by the pegasus-docker-deploy script. For example:

    docker-machine ssh pegasus-keystore

    docker-machine ssh pegasus-submit-node

    docker-machine ssh pegasus-worker1

Once you are logged into the host, you can run docker commands directly to the Docker Engine installed on that host. However, to do so, you need to have root permission. Therefore, **you also should start your docker commands with the word "sudo", otherwise will get the following message: "Cannot connect to the Docker daemon. Is the docker daemon running on this host?"**.

Note that the usernames of the amazon hosts are "ubuntu" by default. You can specify a different username for your amazon EC2 hosts on the amazon configuration file. For example, if you want your username to be "myUsername" you should add the following line to your amazon configuration file:

    AWS_SSH_USER=myUsername

You can end your session on that host by running the *exit* command.

### Listing the Running Containers on a Amazon EC2 host

If you want to check which docker containers are running on a amazon EC2 host, you need first to **set your environment to the Docker Engine installed on that host**, as explained above, and then you need to run the following command:

    docker ps

### Logging Into a Docker Container

In order to log into a docker container running on top of one amazon EC2 host, first you need to know on which host the container is running. If you want to check this information, you can refer to the section above about how to list the running containeirs on a amazon EC2 host.

Once you know the name of the container and the name of the host, you need to set your enviroment to the Docker Engine installed on that host, as explained above, and then run the docker exec command:

    docker exec -it [container_name] bash

*container_name* is the name of the container you want to log into. This command will start a interactive bash on that container so that you can run commands using it.

For example, if you want to log into the submit container running on the top of the pegasus-submit-node EC2 host, you should run the following two commands:

    eval $(docker-machine env --swarm pegasus-submit-node)
    docker exec -it submit bash

If you do not set your environment before running the *docker exec* command, you will get a message saying that there is no container named submit.

You can also **log into the submit container as root by adding the option "-u 0"** as follows:

    eval $(docker-machine --swarm pegasus-submit-node)
    docker exec -it -u 0 submit bash

Note that the default username for the pegasus docker containers is "tutorial". If you need to run commands as root, the password for this username is "pegasus123".

### Copying Files and Directories From/To Local Machine To/From Amazon EC2 Host

If you want to either copy files/directories from your local machine to a amazon EC2 host or copy files from a EC2 host to your local machine, you can use the *docker-machine scp* command:

    docker-machine scp [source] [destination]

*source* is the path to the file/directory you want to copy and *destination* is the path where the file/directory should be placed. Paths within a **amazon EC2 host** must start with the name of the host followed by a colon (:). For example, if you want to transfer a file/directory named "input" located on your local machine's home directory to the home directory of a EC2 host named pegasus-submit-node (/home/ubuntu/), you should run the following command:

    docker-machine scp ~/input pegasus-submit-node:/home/ubuntu/input

Or if you want to copy a file/directory named "output" from the home directory of a amazon EC2 host named pegasus-submit-node to your home directory, you should run this command:

    docker-machine scp pegasus-submit-node:/home/ubuntu/output ~/output

### Copying Files or Directories From/To Amazon EC2 host To/From Pegasus' Docker Containers

If you want to either copy file/directories from your a Amazon EC2 host to the Pegasus Docker container which is running on it, or copy files from a Pegasus Docker container to the Amazon EC2 host on which the container is running, you can run the *docker cp* command **from the host as root**:

    sudo docker cp [source] [destination]

*source* is the path to the file/directory you want to copy and *destination* is the path where the file/directory should be placed. Path within a **container** must start with the name of the container followed by a colon (:). **Note that you need to log into the host before running this command.** For example, if you want to transfer a file named "input" located on the home directory of a amazon EC2 host named pegasus-submit-node to the home directory of a pegasus' docker container named submit running on top of that host, you should run the following commands from your local machine: 

    docker-machine ssh pegasus-submit-node
    sudo docker cp ~/input submit:/home/tutorial/input

Or, if you want to copy a file/directory named "output" from the home directory of a pegasus docker container named submit to the home directory of the amazon EC2 host, on which the container is running, named pegasus-submit-node, you should run the following commands from your local machine:

    docker-machine ssh pegasus-submit-node
    sudo docker cp submit:/home/tutorial/output ~/output

### Copying Files or Directories From/To Your Local Machine to Pegasus Docker Containers

There is no direct way of accomplishing this. In order to do this, you first need to transfer the file from your local machine to the EC2 host and then transfer it from the host to the containeir. Or first transfer the file from the container to the EC2 host and then from the host to your local machine. Therefore, you need to combine the two type of file transfers explained above.

### Terminating an Amazon EC2 Host

In order to terminate an amazon EC2 host and all the containers running on it, you can run the following command from your local machine:

    docker-machine rm -f [hostname]

*hostname* is the name of the host you want to terminate.

For example, if you want to terminate the EC2 host named pegasus-submit-node and all containers running on it, you can run the following command from your local machine:

    docker-machine rm -f pegasus-submit-node

## pegasus-docker-deploy script

The first thing the script does is to read the amazon configuration file and export some environment variables required to start the instances on amazon EC2. **Note that once the script is finished, those environment variables will be unset, meaning that if you want to use docker-machine commands that relate with amazon EC2 you will have to export those variables again, otherwise you will not have permission to do anything.**

Then this script starts one host on EC2 called **pegasus-keystore** using the docker-machine tool. The host's configurations will be the same as those defined on the aws configuration file. The configurations that are not present on that file will be the default ones. This host will be used to start the key-value store required by the multi-host network. The key-value store holds information about the network. 

When the first host is started, docker-machine tool creates a security group called *docker-machine*. This is the default security group which is used by the script. It does not support other security groups. After starting the key-store value host on EC2, the script opens the required ports for the docker-machine security group so that all **hosts** in the cluster can communicate among themselves. 

After opening the required ports, the script runs a Consul docker container on that recently started host. This Consul container will act as the key-value store required by the network used by the swarm cluster. All EC2 hosts must advertise themselves to this container in order to be visible and reachable through the overlay network. 

Then, it starts many hosts on EC2 using the docker-machine tool. The configurations of all of these hosts will be the same as those defined on the aws configuration file. The configurations that are not present on that file will be the default ones. The first host the script starts in this step is called pegasus-submit-node. This host is the swarm manager (master) node and will be the host that will run the pegasus submit docker container. Then the script creates the number provided as third argument (x) of worker hosts on EC2. These hosts are called pegasus-worker'n' (1 < 'n' <= x). They will be the swarm worker nodes and each one of these hosts will run one pegasus worker docker container.

After creating all this EC2 hosts, the script will create the overlay network, which will be used by all **containers** to communicate among themselves.

When these EC2 hosts are started, the docker-machine tool also installs docker and configures docker swarm on every host. Therefore, each host will have one Docker Engine running. In the following steps, the script builds docker images and runs docker containers on the hosts so that we have a cluster of containers running on the top of Amazon's EC2 machines. To do so, first the script copies the pegasus' docker image builder to each EC2 host. It starts copying it to the swarm manager (pegasus-submit-node) and then to the swarm workers (pegasus-worker'n'). The name of the copied script on the hosts will be *build.sh*

Once the image builder script is copied to the hosts, the pegasus-docker-deploy script will log into each host, via ssh, and run the script. It takes a while for the images to be built on the hosts. When the docker images have been created, the last thing left to do is to run the containers using the docker images that were built on the hosts. **Each amazon EC2 host will run one docker container**. Then, the script runs one pegasus submit docker container on the pegasus-submit-node EC2 host. This container is called *submit*. Finally, it runs one pegasus worker docker container on each pegasus-worker EC2 host. These containers are called *worker'n'* (1 < 'n' <= x).

Therefore, in the end, you will see the following hosts on EC2: **pegasus-keystore, pegasus-submit-node, pegasus-worker1, pegasus-worker2, etc.** On the pegasus-keystore host you will see one docker container named **consul** running. On the pegasus-submit-node you will see one docker container named **submit** running. And finally, on each pegasus-worker'n' host you will see one docker container named **worker'n'** (1 < 'n' < x) running. 

The last thing the script does is to log into the submit container so that you can run commands on that container using your terminal. If you run the *pegasus-version* command you should be able to check that pegasus is installed. Also, you can run the command *condor_status* to check that all your submit and workers machines are available and ready to be used.

## About Docker Machine

From the Docker Machine [official website] (https://docs.docker.com/machine/):

"Docker Machine is a tool that lets you install Docker Engine on virtual hosts, and manage the hosts with docker-machine commands. You can use Machine to create Docker hosts on your local Mac or Windows box, on your company network, in your data center, or on cloud providers like AWS or Digital Ocean.

Using docker-machine commands, you can start, inspect, stop, and restart a managed host, upgrade the Docker client and daemon, and configure a Docker client to talk to your host.

Point the Machine CLI at a running, managed host, and you can run docker commands directly on that host. For example, run `docker-machine env default` to point to a host called default, follow on-screen instructions to complete env setup, and run `docker ps`, `docker run hello-world`, and so forth."

For this project, Docker Machine was used to start the hosts on AWS EC2 and to create the Swarm cluster.

## About Docker Swarm

From the Docker Swarm [official website] (https://docs.docker.com/swarm/):
"Docker Swarm is native clustering for Docker. It turns a pool of Docker hosts into a single, virtual Docker host."

For this project, Docker Swarm was used to create this single virtual Docker host from all the Docker hosts started on Amazon EC2. We set the **pegasus-submit-node** host as the swarm manager so that you can monitor your swarm cluster. From that host, you can see all containers that are running on your cluster, independent of the host on which they are running.

## About the Overlay Network

As we are using a docker multi-host environment, we decided to use an overlay network to connect all the containers. This type of network requires a key-value store that "holds information about the network state which includes discovery, networks, endpoints, IP addresses, and more". For this project, we used Consul container running on the **pegasus-keystore** host as the key-value store.

When each Amazon EC2 host is started using docker-machine, it advertise itself to the key-value store to Consul so that it can reach other hosts and other hosts can reach it. Then, when we use the `docker run` command to run the Pegasus Docker Container on the top of this host, we set the default network for the container as the overlay network we created. This way, all containers are connect through the overlay network and the hosts can be reachable through the Consul container running on the key-value store host. 

You can find more information about docker multi-host networking on its [official website] (https://docs.docker.com/engine/userguide/networking/dockernetworks/) 

## Troubleshooting

This section is meant to help you in some of the issues you can run into while running the pegasus-docker-deploy script.

### AWS Credentials

If have not installed and configured the AWS CLI correctly, you will not be able to run the script correctly. It is extremly important that you make sure that you aws keys are configured in the AWS CLI.

Also, if you do not follow the instructions present on the "AWS Configuration File" section above, you will get an error about you credentials being invalid.

### Opening Ports

The first time you run the script, the docker-machine security group will be created and the required ports will be opened, as explained in the "pegasus-docker-deploy script" section above. However, when you terminate the cluster, this security group will remain in your AWS account and when you run the script again later those ports will be already opened. In this case, you will notice a few warning messages in this step about the script failling when trying to open the ports because they cannot be duplicated. You do not need to worry about these messages.

### API Version

After changing your environment by running the `eval $(docker-machine env ...)` command and trying to execute docker commands maybe you can run into a message about the Docker API versions being different between the hosts. If this is the case, you need to upgrade the Docker Engine either in your local machine or in the host you are setting your environment to, whatever has the least recent Docker API version. You can check those version by changing the enviroment for your local machine or for the EC2 host and running the `docker version` command.

Once you know which host has the least recent version, you now need to set the environment for that host and run the `docker upgrade` command.

If the error persists, you can set the DOCKER_API_VERSION environment variable to the least recent version. This is not the recommended way of solving this issue, but it usually works. You can do this by running the following command in your local machine.

    export DOCKER_API_VERSION=[least_recent_docker_api_version]

This issue usually is caused when the Docker Engine installed on your hosts by the Docker Machine tool is not the most updated one. It is Docker Machine's issue.

### Copying Files

If you are trying to copy files using the upload and download scripts and you are getting a message saying that some directory (source or destination) cannot be found, make sure that you are passing the whole path for the container's path. **The tilde mark (~) will not stand for the container's home directory. You must use '/home/tutorial/'.**

## Useful Commands

In this section we list some commands that were explained in the sections above. If you need more information about any command, please refer to those sections and/or to the corresponding official website.

### Provided Scripts

Below are the general commands to run to scripts that are provided in this repository.

#### Cluster creation

    ./pegasus-docker-deploy [path_to_aws_configuration_file] [path_to_pegasus_docker_builder_file] [number_of_worker_nodes]

#### Log into Pegasus submit container as root

    ./pegasus-docker-login root

#### Log into Pegasus submit container as user

    ./pegasus-docker-login

#### Copying file or directory from your local machine to Pegasus submit container

    ./pegasus-docker-upload [source] [destination]

#### Copying file or directory from Pegasus submit container to your local machine

    ./pegasus-docker-download [source] [destination]

#### Cluster termination

    ./pegasus-docker-terminate [number_of_worker_nodes]

### Docker Machine Related

Here you find some useful docker machine commands. These commands do not depend on which Docker Enviroment you are set up to. You can run them in any docker environment.

#### List the hosts and check your docker enviroment

    docker-machine ls

#### Log into a amazon EC2 host

    docker-machine ssh [hostname]

#### Copy files from/to your local machine to/from an Amazon EC2 host

    docker-machine scp [source] [destination]

#### Terminate an Amazon EC2 host

    docker-machine rm -f [hostname]

### Docker Related

Here you find some useful docker commands. These commands depend on which docker enviroment you are set up. Therefore, it is recommended that you set your docker enviroment to the right Docker Engine before running them.

#### Docker Enviroment Set up

    eval $(docker-machine env [options] [hostname])

#### Set your enviroment to the Docker Engine installed on your local machine

    eval $(docker-machine env -u)

#### List the docker containers

    docker ps

#### Log into a docker container as user

    docker exec -it [container_name] bash

#### Log into a docker container as root

    docker exec -it -u 0 submit bash

#### Copy files from/to an Amazon EC2 host to/from a docker container

    sudo docker cp [source] [destination]
