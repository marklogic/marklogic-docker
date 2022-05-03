<!-- Space: ENGINEERING -->
<!-- Parent: MarkLogic Docker Documentation for DockerHub and GitHub -->
<!-- Title: EA4 Review -->

<!-- Include: wiki-disclaimer.md -->
<!-- Include: ac:toc -->
<!-- Include: dockerhub-tos.md -->
# Table of contents
 * [Introduction](#Introduction)
 * [Prerequisites](#Prerequisites)
 * [Supported tags](#Supported-tags)
 * [Architecture reference](#Architecture-reference)
 * [MarkLogic](#MarkLogic)
 * [Using this Image](#Using-this-Image)
 * [Configuration](#Configuration)
 * [Clustering](#Clustering)
 * [Upgrading to the latest MarkLogic Docker Release](#Upgrading-to-the-latest-MarkLogic-Docker-Release)
 * [Backing Up and Restoring a Database](#Backing-Up-and-Restoring-a-Database)
 * [Debugging](#Debugging)
 * [Clean up](#Clean-up)
 * [Known Issues and Limitations](#Known-Issues-and-Limitations)
 * [Older Supported Tags](#Older-Supported-Tags)

# Introduction
This README serves as a technical guide for using MarkLogic Docker and MarkLogic Docker images. These tasks are covered in this README:
- How to use images to setup initialized/uninitialized MarkLogic servers
- How to use Docker compose and Docker swarm to setup single/multi node MarkLogic cluster
- How to enable security using Docker secrets
- How to mount volumes for Docker containers 
- How to upgrade to the latest MarkLogic Docker release  
- How to back up and restore a database
- How to clean up MarkLogic Docker containers and resources

# Prerequisites

- Examples in this document use Docker Engine and Docker CLI to create and manage containers. Follow the documentation for instructions on how to install Docker: see Docker Engine (https://docs.docker.com/engine/)
- In order to get the MarkLogic image from Dockerhub, you need a Dockerhub account. Follow the instruction on [Docker Hub](https://hub.docker.com/signup) to create a Dockerhub account.
- To access the MarkLogic Admin interface and App Servers in our examples, you need a desktop browser. See "Supported Browsers" in the [support matrix](https://developer.marklogic.com/products/support-matrix/) for a list of supported browsers.

# Supported tags

Note: MarkLogic Server Docker images follow a specific tagging format: `{ML release version}-{platform}-{ML Docker release version}-ea`

- 10.0-9-centos-1.0.0-ea4 - This current release of the MarkLogic Server Developer Docker image includes all features and is limited to developer use
- [Older Supported Tags](#older-supported-tags)

# Architecture reference

Docker images are maintained by MarkLogic. Send feedback to the MarkLogic Docker team: docker@marklogic.com

Supported Docker architectures: x86_64

Base OS: CentOS

Latest supported MarkLogic Server version: 10.0-9

Published image artifact details: https://github.com/marklogic/marklogic-docker, https://hub.docker.com/_/marklogic

# MarkLogic

[MarkLogic](http://www.marklogic.com/) is the only Enterprise NoSQL database. It is a new generation database built with a flexible data model to store, manage, and search JSON, XML, RDF, and more - without sacrificing enterprise features such as ACID transactions, certified security, backup, and recovery. With these capabilities, MarkLogic is ideally suited for making heterogeneous data integration simpler and faster, and for delivering dynamic content at massive scale.

MarkLogic documentation is available at [http://docs.marklogic.com](https://docs.marklogic.com/).

# Using this Image

With this image, you have the option to either create an initialized or an uninitialized MarkLogic Server.

- Initialized: admin credentials are set up as part of container startup process.
- Unintialized: admin credentials are created by the user after MarkLogic has started. To create the credentials you can use the GUI (see the MarkLogic Installation documentation: https://docs.marklogic.com/guide/installation/procedures#id_84772) or you can use APIs (see the scripting documentation: https://docs.marklogic.com/10.0/guide/admin-api/cluster).

## Initialized MarkLogic Server
For an initialized MarkLogic Server, admin credentials are required to be passed in while creating the Docker container. The Docker container will have MarkLogic Server installed and initialized, and databases and app servers created. A security database will be created to store user data, roles, and other security information. MarkLogic Server credentials, passed in as environment variable parameters while running a container, will be stored as part of the admin user in the security database. These admin credentials can be used to access MarkLogic Server Admin interface on port 8001 and other app servers with their respective ports.

To create an initialized MarkLogic Server, pass in environment variables and replace `{insert admin username}`/`{insert admin password}` with actual values for admin credentials. Optionally, you can pass license information in `{insert license}`/`{insert licensee}` to apply your MarkLogic license. To do this, run this this command: 

```
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME={insert admin username} \
     -e MARKLOGIC_ADMIN_PASSWORD={insert admin password} \
     -e LICENSE_KEY="{insert license}" \
     -e LICENSEE="{insert licensee}" \
     store/marklogicdb/marklogic-server:10.0-9-centos-1.0.0-ea4
```
Example run:
```
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \ 
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME=admin \
     -e MARKLOGIC_ADMIN_PASSWORD=Areally!PowerfulPassword1337 \
     store/marklogicdb/marklogic-server:10.0-9-centos-1.0.0-ea4
```
Wait about a minute for MarkLogic Server to initialize before checking the ports. To verify the successful installation and initialization, log into the MarkLogic Server Admin Interface using the admin credentials used in the command above. Go to http://localhost:8001. You can also verify the configuration by following the procedures outlined in the MarkLogic Server documentation. See the MarkLogic Installation documentation [here](https://docs.marklogic.com/guide/installation/procedures#id_84772).

## Uninitialized MarkLogic Server
For an uninitialized MarkLogic Server, admin credentials or license information are not required while creating the container. The Docker container will have MarkLogic Server installed and ports exposed for app servers as specified in the run command. Users can access the MarkLogic Admin Interface at http://localhost:8001 and manually initialize the MarkLogic Server, create the admin user, databases, and install the license. See the MarkLogic Installation documentation [here](https://docs.marklogic.com/guide/installation/procedures#id_84772).

To create an uninitialized MarkLogic Server with [Docker CLI](https://docs.docker.com/engine/reference/commandline/cli/), run this command:

```
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     store/marklogicdb/marklogic-server:10.0-9-centos-1.0.0-ea4
```
The example output will contain a hash of the image ID: `f484a784d99838a918e384eca5d5c0a35e7a4b0f0545d1389e31a65d57b2573d`

Wait for about a minute, before going to the MarkLogic Admin Interface at http://localhost:8001. If the MarkLogic container has started successfully on Docker, you should see a configuration screen allowing you to initialize the server as shown at: https://docs.marklogic.com/guide/installation/procedures#id_60220.  


Note that the examples in this document can interfere with one another.  We recommend that you stop all containers before running the examples. See the [Clean up](#clean-up) section at the end of this document for more details.

## Persistent Data Volume

A MarkLogic Docker container stores data in `/var/opt/MarkLogic` which is persistent in a Docker managed volume. We recommend that you use named volumes instead of bind mounts as suggested by the [Docker documentation](https://docs.docker.com/storage/volumes/).

The following command will list previously created volumes:

```
$ docker volume ls
```
If the instructions in the **Using this Image** section are followed, the previous command should output at least two volume identifiers:
```
DRIVER    VOLUME NAME
local     0f111f7336a5dd1f63fbd7dc07740bba8df684d70fdbcd748899091307c85019
local     1b65575a84be319222a4ff9ba9eecdff06ffb3143edbd03720f4b808be0e6d18
```

The following command uses a named volume and named container in order to make management easier:

```
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     --name MarkLogic_cont_1 \
     --mount src=MarkLogic_vol_1,dst=/var/opt/MarkLogic \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME={insert admin username} \
     -e MARKLOGIC_ADMIN_PASSWORD={insert admin password} \
     store/marklogicdb/marklogic-server:10.0-9-centos-1.0.0-ea4
```

Above command will start a Docker container `MarkLogic_cont_1` running MarkLogic Server and associate the named Docker volume `MarkLogic_vol_1` with it.

Run this command to check the volumes:
```
$ docker volume ls
```

The output from should now contain a named volume `MarkLogic_vol_1`:
```
DRIVER    VOLUME NAME
local     0f111f7336a5dd1f63fbd7dc07740bba8df684d70fdbcd748899091307c85019
local     1b65575a84be319222a4ff9ba9eecdff06ffb3143edbd03720f4b808be0e6d18
local     MarkLogic_vol_1
```

# Configuration

MarkLogic Server Docker containers are configured using a set of environment variables.


| env var                       | value                           | required                          | default   | description                                        |
| ------------------------------- | --------------------------------- | ----------------------------------- | ----------- | ---------------------------------------------------- |
| MARKLOGIC_INIT                | true                            | no                                |           | when set to true, will initialize MarkLogic           |
| MARKLOGIC_ADMIN_USERNAME      | jane_doe                        | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic Server admin user                           |
| MARKLOGIC_ADMIN_PASSWORD      | pass                            | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic Server admin password                       |
| MARKLOGIC_ADMIN_USERNAME_FILE | secret_username                 | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic Server admin username via Docker secrets    |
| MARKLOGIC_ADMIN_PASSWORD_FILE | secret_password                 | required if MARKLOGIC_INIT is set | n/a       | set MarkLogic Server admin password via Docker secrets    |
| MARKLOGIC_JOIN_CLUSTER        | true                            | no                                |           | will join cluster via MARKLOGIC_BOOTSTRAP_HOST          |
| MARKLOGIC_BOOTSTRAP_HOST           | someother.bootstrap.host.domain | no                                | bootstrap | must define if not connecting to default bootstrap |
| LICENSE_KEY           | license key                     | no                                | n/a       | set MarkLogic license key                          |
| LICENSEE            | licensee information            | no                                | n/a       | set MarkLogic licensee information                 |
|INSTALL_CONVERTERS   | true                            | no                                | false     | Installs converters for the client if they are not already installed | 

**IMPORTANT:** The use of [Docker secrets](https://docs.docker.com/engine/swarm/secrets/) is new in the store/marklogicdb/marklogic-server:10.0-7.3-centos-1.0.0-ea image and will not work with older versions of the Docker EA image. The Docker compose examples that follow use secrets. If you want to use these examples with an older version of the image, you need to update the examples to use environment variables instead of secrets.

## Configuring swap space

MarkLogic recommends that swap space be configured for production deployments to reduce the possibility of ‘out of memory’ errors. For more details, see [MarkLogic recommendations for swap space](https://help.marklogic.com/knowledgebase/article/View/21/19/swap-space-requirements) and [configuring "swappiness"](https://help.marklogic.com/Knowledgebase/Article/View/linux-swappiness).

In Docker, the amount of memory and swap space that are available to MarkLogic Server can be controlled using the "--memory" and "--memory-swap" settings. See the Docker documentation [--memory-swap-details](https://docs.docker.com/config/containers/resource_constraints/#--memory-swap-details) for more details. For example, if you want to run a MarkLogic container with 64GB of memory and 32GB of swap, you would specify the following with your docker run command:
```
--memory="64g" --memory-swap="96g"
```
If you want to limit memory to 64GB but allow MarkLogic Server to use swap space (up to the amount available on host system), specify the following with your docker run command:
```
--memory="64g" --memory-swap="-1"
```
To allow MarkLogic Server to use unlimited memory and swap space (up to the amount available on the host system), do not specify either "--memory" or "--memory-swap".

## Configuring HugePages

By default, if HugePages are configured on the host, the MarkLogic instance running in a container will attempt to allocate up to 3/8 of the container memory limit as HugePages. For example, consider a host with 128GB of RAM, 48GB HugePages, and running two MarkLogic containers, each with 64GB memory limit. The MarkLogic instance in each container will only allocate up to 24GB in HugePages (3/8 * 64GB).

You can change the number of HugePages available to each MarkLogic container by setting the "ML_HUGEPAGES_TOTAL" environment variable. Set the variable for each MarkLogic container to the desired number of HugePages. For example, to disable the HugePages for specific container, specify the following with your Docker run command:
```
-e ML_HUGEPAGES_TOTAL=0
```

# Clustering

MarkLogic Server Docker containers ship with a small set of scripts, making it easy to create clusters. See the [MarkLogic documentation](https://docs.marklogic.com/guide/concepts/clustering) for more about clusters. The following three examples show how to create MarkLogic Server clusters with Docker containers. The first two use Docker compose scripts to create one-node and three-node clusters. See the documentation for [Docker compose](https://docs.docker.com/compose/) for more details. The third example demonstrates a container setup on separate VMs.

The credentials for the admin user are configured using Docker secrets, and are stored in `mldb_admin_username.txt` and `mldb_admin_password.txt` files.

## Single node MarkLogic Server on a single VM
Single node configurations are used primarily on a development machine with a single user.

Create these files on your host machine: `marklogic-centos.yml`, `mldb_admin_username.txt`, and `mldb_admin_password.txt`. Run example Docker commands from the same directory where the files created. 

**marklogic-centos.yml**

```
#Docker compose file sample to setup single node cluster
version: '3.6'
services:
    bootstrap:
      image: store/marklogicdb/marklogic-server:10.0-9-centos-1.0.0-ea4
      container_name: bootstrap
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - TZ=Europe/Prague
      volumes:
        - MarkLogic_1n_vol1:/var/opt/MarkLogic
      secrets:
          - mldb_admin_password
          - mldb_admin_username
      ports:
        - 8000-8010:8000-8010
        - 7997:7997
      networks:
      - external_net
secrets:
  mldb_admin_password:
    file: ./mldb_admin_password.txt
  mldb_admin_username:
    file: ./mldb_admin_username.txt
networks:
  external_net: {}
volumes:
  MarkLogic_1n_vol1:
```

**mldb_admin_username.txt**

```
#This file will contain the MARKLOGIC_ADMIN_USERNAME value

{insert admin username}
```

**mldb_admin_password.txt**

```
#This file will contain the MARKLOGIC_ADMIN_PASSWORD value

{insert admin password}
```

Once the files are ready, run this command to start the MarkLogic Server container.

```
$ docker-compose -f marklogic-centos.yml up -d
```
The previous command starts a container running MarkLogic Server named "bootstrap".

Run this next command to verify if the container is running:
```
$ docker ps
```
If the containers are running correctly, this command lists all the Docker containers running on the host.

After the container is initialized, you can access the MarkLogic Query Console on http://localhost:8000 and the MarkLogic Admin Interface on http://localhost:8001. These ports can also be accessed externally via your hostname or IP address.

## Three node cluster on a single VM

The following is an example of a three-node MarkLogic server cluster created using Docker compose. Create these files on your host machine:  `marklogic-cluster-centos.yml`, `mldb_admin_username.txt`, and `mldb_admin_password.txt`. Run example Docker commands from the same directory where the files created.

**marklogic-cluster-centos.yml**

```
#Docker compose file sample to setup a three node cluster
version: '3.6'
services:
    bootstrap:
      image: store/marklogicdb/marklogic-server:10.0-9-centos-1.0.0-ea4
      container_name: bootstrap_3n
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - TZ=Europe/Prague
      volumes:
        - MarkLogic_3n_vol1:/var/opt/MarkLogic
      secrets:
          - mldb_admin_password
          - mldb_admin_username
      ports:
        - 7100-7110:8000-8010
        - 7197:7997
      networks:
      - external_net
    node2:
      image: store/marklogicdb/marklogic-server:10.0-9-centos-1.0.0-ea4
      container_name: node2
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - MARKLOGIC_JOIN_CLUSTER=true
        - TZ=Europe/Prague
      volumes:
        - MarkLogic_3n_vol2:/var/opt/MarkLogic
      secrets:
        - mldb_admin_password
        - mldb_admin_username
      ports:
        - 7200-7210:8000-8010
        - 7297:7997
      depends_on:
      - bootstrap
      networks:
      - external_net
    node3:
      image: store/marklogicdb/marklogic-server:10.0-9-centos-1.0.0-ea4
      container_name: node3
      dns_search: ""
      environment:
        - MARKLOGIC_INIT=true
        - MARKLOGIC_ADMIN_USERNAME_FILE=mldb_admin_username
        - MARKLOGIC_ADMIN_PASSWORD_FILE=mldb_admin_password
        - MARKLOGIC_JOIN_CLUSTER=true
        - TZ=Europe/Prague
      volumes:
        - MarkLogic_3n_vol3:/var/opt/MarkLogic
      secrets:
        - mldb_admin_password
        - mldb_admin_username
      ports:
        - 7300-7310:8000-8010
        - 7397:7997
      depends_on:
      - bootstrap
      networks:
      - external_net
secrets:
  mldb_admin_password:
    file: ./mldb_admin_password.txt
  mldb_admin_username:
    file: ./mldb_admin_username.txt
networks:
  external_net: {}
volumes:
  MarkLogic_3n_vol1:
  MarkLogic_3n_vol2:
  MarkLogic_3n_vol3:
```

**mldb_admin_username.txt**
```
#This file will contain the MARKLOGIC_ADMIN_USERNAME value

{insert admin username}
```

**mldb_admin_password.txt**
```
#This file will contain the MARKLOGIC_ADMIN_PASSWORD value

{insert admin password}
```

Once the files have been created, run the following command to start the MarkLogic Server container:

```
$ docker-compose -f marklogic-cluster-centos.yml up -d
```

This command will start three Docker containers running MarkLogic Server, named "bootstrap_3n", "node2" and, "node3".

Run this command to verify if the containers are running:
```
$ docker ps
```
This command lists all the Docker containers running on the host.

After the containers are initialized, you can access the MarkLogic Query Console on http://localhost:8000 and the MarkLogic Admin UI at http://localhost:8001. These ports can also be accessed externally via your hostname or IP address.

As in the previous single-node example, each node of the cluster can be accessed with localhost or host machine IP address. The MarkLogic Query Console and MarkLogic Admin UI ports for each container will be different. The ports are defined in the compose file created previously: http://localhost:7101, http://localhost:7201, http://localhost:7301, etc.

### Using ENV for admin credentials in Docker compose

In the previous examples, Docker secrets files were used to specify admin credentials for the MarkLogic Server. If your environment prevents the use of Docker secrets, you can use environmental variables. This approach is less secure, but it is commonly used in development environments. This is not recommended for production environments. In order to use these environment variables in the Docker compose files, remove the secrets section at the end of the Docker compose yml file, and remove the secrets section in each node. Then replace the MARKLOGIC_ADMIN_USERNAME_FILE/MARKLOGIC_ADMIN_PASSWORD_FILE variables with MARKLOGIC_ADMIN_USERNAME/MARKLOGIC_ADMIN_PASSWORD and provide the appropriate values.

Using Docker secrets, username and password information are secured when transmitting the sensitive data from Docker host to Docker containers. To prevent any attacks, the login information is not available as an environment variable. However, these values are stored in a text file and persisted in an in-memory file system inside the container. We recommend that you delete the Docker secrets information once the cluster is up and running.

## Three node cluster setup on multiple VMs
This next example shows how to create containers on separate VMs and connect them with each other using Docker Swarm. For more details on Docker Swarm, see https://docs.docker.com/engine/swarm/. All of the nodes inside the cluster must be part of the same network in order to communicate with each other. We use the overlay network that allows for container communication on separate hosts. For more information on overlay networks, please refer https://docs.docker.com/network/overlay/.

### VM#1

Follow these steps to set up the first node ("bootstrap") on VM1.

Initialize the Docker Swarm with this command:

```
$ docker swarm init
```
Copy the output from this step. The other VMs will need this information to connect them to the swarm. The output will be similar to this: `docker swarm join --token xxxxxxxxxxxxx {VM1_IP}:2377`. 

Use this command to create a new network:

```
$ docker network create --driver=overlay --attachable ml-cluster-network
```

Use this command to verify the ml-cluster-network has been created:

```
$ docker network ls
```
The `network ls` command will list all the networks on the host.

Run this command to start the Docker container, adding your username and password to the command. It will start the Docker container (named "bootstrap") with MarkLogic Server initialized.

```
$ docker run -d -it -p 7100:8000 -p 7101:8001 -p 7102:8002 \
     --name bootstrap -h bootstrap.marklogic.com \
     -e MARKLOGIC_ADMIN_USERNAME={insert admin username} \
     -e MARKLOGIC_ADMIN_PASSWORD={insert admin password} \
     -e MARKLOGIC_INIT=true \
     --mount src=MarkLogicVol,dst=/var/opt/MarkLogic \
     --network ml-cluster-network \
     --dns-search "marklogic.com" \
     store/marklogicdb/marklogic-server:10.0-9-centos-1.0.0-ea4
```
If successful, the command will output the ID for the new container. Give the container a couple of minutes to get initialized. Continue with the next section to create additional nodes for the cluster.

### VM#n

Follow the next steps to set up an additional node (for example ml2) on VM#n.

Run the Docker `swarm join` command that you got as output when you set up VM#1 previously.

```
$ docker swarm join --token xxxxxxxxxxxxx {VM1_IP}:2377
```
This command adds the current node to the swarm initialized earlier. 

Start the Docker container (ml2.marklogic.com) with MarkLogic Server initialized, and join to the same cluster as you started/initialized on VM#1. Be sure to add your admin username and password for the bootstrap host in the Docker start up command that follows.

```
$ docker run -d -it -p 7200:8000 -p 7201:8001 -p 7202:8002 \
     --name ml2 -h ml2.marklogic.com \
     -e MARKLOGIC_ADMIN_USERNAME={insert admin username} \
     -e MARKLOGIC_ADMIN_PASSWORD={insert admin password} \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_JOIN_CLUSTER=true \
     --mount src=MarkLogicVol,dst=/var/opt/MarkLogic \
     --network ml-cluster-network \
     store/marklogicdb/marklogic-server:10.0-9-centos-1.0.0-ea4
```

When you complete these steps, you will have multiple containers; one on each VM, and all connected to each other on the 'ml-cluster-network' network. All the containers will be part of same cluster.

# Upgrading to the latest MarkLogic Docker Release

MarkLogic has extensive documentation about upgrades, see [https://docs.marklogic.com/guide/relnotes/chap2](https://docs.marklogic.com/guide/relnotes/chap2). Other than the uninstall and install of the MarkLogic RPMs, the overall processes and compatibility notes for upgrades remain the same when you run MarkLogic in containers. Instead of uninstalling and installing the MarkLogic RPMs, use the following procedure to upgrade a container instance to a newer release of MarkLogic. Be sure to follow the sequence described in the documentation for rolling upgrades [https://docs.marklogic.com/guide/admin/rolling-upgrades](https://docs.marklogic.com/guide/admin/rolling-upgrades) if you need to upgrade with zero downtime.

To upgrade MarkLogic Docker from release 10.x to the latest release, perform following steps:
Note: In the below example, we are upgrading the container to marklogic-server:10.0-9.1-centos-1.0.0.

1. Stop the MarkLogic Docker container.
Use following command to stop the container:

```
$ docker stop container_id
```
2. Now, run a MarkLogic Docker container using the latest release of the Docker image. Use the same volume, mounted to the container that was running the older release.
```
$ docker run -d -it -p 8000:8000 -p 8001:8001 -p 8002:8002 \
     --name MarkLogic_cont_2 \
     --mount src=MarkLogic_vol_1,dst=/var/opt/MarkLogic \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME={insert admin username} \
     -e MARKLOGIC_ADMIN_PASSWORD={insert admin password} \
    store/marklogicdb/marklogic-server:10.0-9.1-centos-1.0.0
```
3. In a browser, open the MarkLogic Admin Interface for the container (http://<vm_ip>:8001/).
4. When prompted by the Admin Interface to upgrade the databases and configuration files, click the Ok button to confirm the upgrade.
5. Once the upgrade is complete, the Admin interface will reload with the new MarkLogic release. 

# Backing Up and Restoring a Database

When creating a backup for a database on a MarkLogic Docker container, verify that the directory used for the backup is mounted to a directory on the Docker host machine or Docker volume. This is so that the database backup persists even after the container is stopped.

This command is an example of mounting the directory /space used for backup on a Docker volume, while running the MarkLogic Docker container.
```
$ docker run -d -it -p 7000:8000 -p 7001:8001 -p 7002:8002 \
     --mount src=MarkLogic_vol_1,dst=/var/opt/MarkLogic \
     --mount src=MarkLogic_vol_1,dst=/space \
     -e MARKLOGIC_INIT=true \
     -e MARKLOGIC_ADMIN_USERNAME={insert admin username} \
     -e MARKLOGIC_ADMIN_PASSWORD={insert admin password} \
     store/marklogicdb/marklogic-server:10.0-9.1-centos-1.0.0
```
The /space mounted on the Docker volume can now be used as backup directory for backing up/restoring a database using the procedures described in the MarkLogic documentation: https://docs.marklogic.com/guide/admin/backup_restore

# Debugging

## Accessing a MarkLogic Container while it's running

The following is a set of steps to run to access a container while it is running, and to do some basic debugging once you access the container.

1. Access the machine running the Docker container. This is typically done using SSH or by having physical access to the machine hosting the container.
2. Get the container ID for the MarkLogic container running on the machine. To do this, run the following command:

```
$ docker container ps --filter ancestor=store/marklogicdb/marklogic-server:10.0-9-centos-1.0.0-ea4 -q
```
In this example command `store/marklogicdb/marklogic-server:10.0-9-centos-1.0.0-ea4` is an image ID. Your container ID may be different for your machine.

Example output:

```
f484a784d998
```

If you don't know the image name, you can search for it without a filter:

```
$ docker container ps
```

Here's an example of unfiltered output from that command:

```
CONTAINER ID   IMAGE                                                        COMMAND                  CREATED          STATUS          PORTS                                  NAMES
f484a784d998   store/marklogicdb/marklogic-server:10.0-9-centos-1.0.0-ea4   "/usr/local/bin/star…"   16 minutes ago   Up 16 minutes   25/tcp, 7997-7999/tcp, 8003-8010/tcp, 0.0.0.0:8000-8002 8000-8002/tcp   vibrant_burnell
```

3. Run a command to access a remote shell on the container.

For this example command, `f484a784d998` is the container ID from the prior step. The one assigned to your container will be different. 

```
$ docker exec -it f484a784d998 /bin/bash
```

4. To verify that MarkLogic is running, use this command:

```
$ sudo service MarkLogic status
```

Example output:  

```
MarkLogic (pid  34) is running...
```

5. To read the logs for the container, navigate to `/var/opt/MarkLogic/Logs`. View the logs using a reader like `vi`.

For example, you can list the 8001 error logs, and view them with a single command:

```
$ sudo cd /var/opt/MarkLogic/Logs && ls && vi ./8001_ErrorLog.txt
```

6. To exit the container when you are through debugging, use the exit command:

```
$ exit
```

# Clean up

## Basic Example Removal
These are the steps you can use to remove the containers created in the "Using this Image" section of the text. It is important to remove resources after development is complete to free up ports and resources when they are not in use.  

Use this command to stop a container, replacing `container_name` with the name(s) of the container(s) found when using the command: `docker container ps`.
```
$ docker stop container_name
```

Use this command to remove a stopped container: 

```
$ docker rm container_name
```

## Multi and Single Node, Single VM cleanup
This section describes the teardown process for clusters set up on a single VM using Docker compose, as described in the earlier examples.

### Remove compose resources

Resources such as containers, volumes, and networks that were created with compose command can be removed using this command:

```
$ docker-compose -f marklogic-centos.yml down
```

### Remove volumes

Volumes can be removed in a few ways. Adding the `–rm` option while running a container will remove the volume when the container dies. You can also remove a volume by using `prune`. See the following examples for more information.
```
$ docker run --rm -v /foo -v awesome:/bar container image
```

To remove all other unused volumes use this command:

```
$ docker volume prune
```
If the process is successful, the output will list all of the removed volumes.

### Multi-VM Cleanup
For multi-VM setup, first stop and remove all the containers on all the VMs using the commands described in the "Basic Example Removal" section.
Then remove all the volumes with the commands described in the "Remove volumes" section.

Finally, disconnect VMs from the swarm running the following command on each VM:

```
docker swarm leave --force
```
If the process is successful, a message saying the node has left the swarm will be displayed.

# Known Issues and Limitations

10.0-9-centos-1.0.0-ea4

1. Enabling huge pages for clusters containing single-host, multi-container configurations may lead to failure, due to incorrect memory allocation. MarkLogic recommends that you disable huge pages in such architectures.
2. Database replication will only work for configurations having a single container per host, with matching hostname.
3. Using the "leave" button in the Admin interface to remove a node from a cluster may not succeed, depending on your network configuration. Use the Management API to remove a node from a cluster. See: [https://docs.marklogic.com/REST/DELETE/admin/v1/host-config](https://docs.marklogic.com/REST/DELETE/admin/v1/host-config).
4. Rejoining a node to a cluster, that had previously left that cluster, may not succeed.
5. MarkLogic Server will default to the UTC timezone.
6. By default, MarkLogic Server runs as the root user. To run MarkLogic Server as a non-root user, see the following references:
   1. [https://help.marklogic.com/Knowledgebase/Article/View/start-and-stop-marklogic-server-as-non-root-user](https://help.marklogic.com/Knowledgebase/Article/View/start-and-stop-marklogic-server-as-non-root-user)
   2. [https://help.marklogic.com/Knowledgebase/Article/View/306/0/pitfalls-running-marklogic-process-as-non-root-user](https://help.marklogic.com/Knowledgebase/Article/View/306/0/pitfalls-running-marklogic-process-as-non-root-user)

# Older Supported Tags
- 9.0-12-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 9.0-12.2-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 9.0-13-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 9.0-13.1-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 9.0-13.2-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-1-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-2-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-3-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-4-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-4.2-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-4.4-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-5-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-5.1-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-5.2-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-6-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-6.1-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-6.2-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-6.4-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-7-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-7.1-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-7.3-dev-centos - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-1-dev-ubi - MarkLogic Developer Docker image, running on Redhat UBI, including all features and is limited to developer use
- 10.0-2-dev-ubi - MarkLogic Developer Docker image, running on Redhat UBI, including all features and is limited to developer use
- 10.0-3-dev-ubi - MarkLogic Developer Docker image, running on Redhat UBI, including all features and is limited to developer use
- 10.0-7.3-centos-1.0.0-ea - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-8.1-centos-1.0.0-ea2 - MarkLogic Developer Docker image includes all features and is limited to developer use
- 10.0-8.3-centos-1.0.0-ea3 - MarkLogic Developer Docker image includes all features and is limited to developer use
